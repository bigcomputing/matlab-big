/*
 * TODO:
 *   - add support for handling different endian data
 *   - avoid corrupting the server connection when memory
 *     allocation fails
 *   - check if character matrices are handled correctly
 *   - capitalize macros?
 */
#if defined(_MSC_VER)
#include <windows.h>
#include <winsock.h>
#include <process.h>
#else
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>
#endif
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <fcntl.h>

#include "mex.h"

#if defined(_MSC_VER)
#define strcasecmp _stricmp
#define snprintf _snprintf
#define close closesocket
#define getpid _getpid
#endif

/* desc bit definitions */
#define BabelMask               0xff000000
#define MatlabFP                0x02000000

#define SerializationMask       0x00000001
#define UnserializedData        0x00000001
#define SerializedData          0x00000000

#define BinaryMask              0x00000002
#define BinaryData              0x00000002
#define StringData              0x00000000

#define BinaryEndianMask        0x00000004
#define BinaryLittleEndian      0x00000000
#define BinaryBigEndian         0x00000004

#define BinaryComplexityMask    0x00000008
#define BinaryReal              0x00000000
#define BinaryComplex           0x00000008

#define BinaryTypeMask          0x000000f0
#define BinaryTypeUint          0x00000000
#define BinaryTypeInt           0x00000010
#define BinaryTypeFP            0x00000020

#define BinarySizeMask          0x00000f00
#define BinarySize8             0x00000000
#define BinarySize16            0x00000100
#define BinarySize32            0x00000200
#define BinarySize64            0x00000300

/* misc definitions */
#define ModeMaxLen              128
#define NwsNameMaxLen           128
#define OpMaxLen                128
#define SetNameMaxLen           128
#define VarNameMaxLen           128
#define ClassIDNameMaxLen       128
#define MaxDims                 10

/* these should be declared in mex.h */
extern mxArray *mxSerialize();
extern mxArray *mxDeserialize();

/* protocol: the (four digit) number of args, followed, per arg, by a
   20-digit len followed by that many bytes of real data. */

static int      debug = 0;

static mxClassID getClassIDFromName(const char *s)
{
  mxClassID cid;

  if (!strcasecmp(s, "int8"))
    cid = mxINT8_CLASS;
  else if (!strcasecmp(s, "int16"))
    cid = mxINT16_CLASS;
  else if (!strcasecmp(s, "int32"))
    cid = mxINT32_CLASS;
  else if (!strcasecmp(s, "int64"))
    cid = mxINT64_CLASS;
  else if (!strcasecmp(s, "uint8"))
    cid = mxUINT8_CLASS;
  else if (!strcasecmp(s, "uint16"))
    cid = mxUINT16_CLASS;
  else if (!strcasecmp(s, "uint32"))
    cid = mxUINT32_CLASS;
  else if (!strcasecmp(s, "uint64"))
    cid = mxUINT64_CLASS;
  else if (!strcasecmp(s, "single"))
    cid = mxSINGLE_CLASS;
  else if (!strcasecmp(s, "double"))
    cid = mxDOUBLE_CLASS;
  else {
    mexWarnMsgTxt("ignoring unrecognized classid");
    cid = -1;
  }

  return cid;
}

static mxClassID getClassID(int desc)
{
  switch (desc & BinaryTypeMask) {
  case BinaryTypeUint:
    switch (desc & BinarySizeMask) {
    case BinarySize8:
      return mxUINT8_CLASS;
    case BinarySize16:
      return mxUINT16_CLASS;
    case BinarySize32:
      return mxUINT32_CLASS;
    default:
      mexErrMsgTxt("unsupported size for unsigned integer type");
    }
  case BinaryTypeInt:
    switch (desc & BinarySizeMask) {
    case BinarySize8:
      return mxINT8_CLASS;
    case BinarySize16:
      return mxINT16_CLASS;
    case BinarySize32:
      return mxINT32_CLASS;
    default:
      mexErrMsgTxt("unsupported size for integer type");
    }
  case BinaryTypeFP:
    switch (desc & BinarySizeMask) {
    case BinarySize32:
      return mxSINGLE_CLASS;
    case BinarySize64:
      return mxDOUBLE_CLASS;
    default:
      mexErrMsgTxt("unsupported size for floating point type");
    }
  default:
    mexErrMsgTxt("unsupported data type");
  }
}

static mwSize getNumberOfElements(mxClassID cid, int complex, mwSize n)
{
  if (complex) {
    if ((n & 1) != 0) {
      mexWarningMsgTxt("matrix size is not evenly divisible by 2");
      n = 0;
    }
    n >>= 1;
  }

  switch (cid) {
  case mxINT8_CLASS:
  case mxUINT8_CLASS:
    break;
  case mxINT16_CLASS:
  case mxUINT16_CLASS:
    if ((n & 1) != 0) {
      mexWarnMsgTxt("matrix size is not evenly divisible by 2");
      n = 0;
    }
    n >>= 1;
    break;
  case mxINT32_CLASS:
  case mxUINT32_CLASS:
  case mxSINGLE_CLASS:
    if ((n & 3) != 0) {
      mexWarnMsgTxt("matrix size is not evenly divisible by 4");
      n = 0;
    }
    n >>= 2;
    break;
  case mxINT64_CLASS:
  case mxUINT64_CLASS:
  case mxDOUBLE_CLASS:
    if ((n & 7) != 0) {
      mexWarnMsgTxt("matrix size is not evenly divisible by 8");
      n = 0;
    }
    n >>= 3;
    break;
  default:
    mexErrMsgTxt("unsupported classid");
  }

  return n;
}

static void recvN(int s, char *buf, int n)
{
  int   b;
  int   t = 0;

  while (1) {
    if (t == n) return;
    b = recv(s, buf+t, n-t, 0);
    if (b < 1) {
      mexErrMsgTxt("error receiving data from nws server");
    }
    t += b;
  }
}

static int recvNumber(int s, int digits) {
  char  nBuf[128];

  if (digits + 1 > sizeof(nBuf)) mexErrMsgTxt("really, really long number");
  recvN(s, nBuf, digits);
  nBuf[digits] = 0;
  return atoi(nBuf);
}

/* invoker MUST free buffer. */
static char *recvLB(int s, int digits, int *len) {
  char  *buf = NULL;

  *len = recvNumber(s, digits);
  if (!*len) return NULL;

  buf = (char *) mxMalloc(*len + 1);
  if (!buf) {
    mexPrintf("failed to allocate %d bytes.\n", *len);
    mexErrMsgTxt("cannot receive a len/buffer combo");
  }
  recvN(s, buf, *len);
  buf[*len] = 0;

  return buf;
}

static void sendAll(int s, char *buf, int n) {
  int   nleft;
  int   nwritten;

  nleft = n;
  while (nleft > 0) {
    nwritten = send(s, buf, nleft, 0);
    if (nwritten <= 0) {
      mexErrMsgTxt("error writing data to socket");
    }
    nleft -= nwritten;
    buf += nwritten;
  }
}

static void sendNumber(int s, int digits, int n) {
  int   b;
  char  nBuf[128];

  b = snprintf(nBuf, sizeof(nBuf), "%*d", digits, n);
  if (b > sizeof(nBuf)) mexErrMsgTxt("really, really long number");
  sendAll(s, nBuf, b);
}

static void sendLB(int s, int digits, int len, char *buf) {
  sendNumber(s, digits, len);
  sendAll(s, buf, len);
}

static void doConnect( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  struct hostent        *hostEntryPtr;
  char                  hostName[256];
  int                   port;
  int                   s;
  struct sockaddr_in    sa;

  if ((3 != nrhs) || !mxIsChar(prhs[1]) || !mxIsDouble(prhs[2])) {
    mexPrintf("%d, s? %d, d? %d.\n", nrhs, mxIsChar(prhs[1]), mxIsDouble(prhs[2]));
    mexErrMsgTxt("netWorkSpace connect expects two arguments");
  }
  /* Need to think through error checking and where it should occur,
     for the moment will not continue to check as thoroughly as
     previous statement.*/
  mxGetString(prhs[1], hostName, sizeof(hostName));
  port = (int)mxGetScalar(prhs[2]);

  hostEntryPtr = gethostbyname(hostName);
  if (!hostEntryPtr) {
    char        buf[300];

    sprintf(buf, "hostname lookup failed for \"%.*s\"", 256, hostName);
    mexErrMsgTxt(buf);
  }

  memset(&sa, 0, sizeof(sa));
  memcpy(&sa.sin_addr, hostEntryPtr->h_addr, hostEntryPtr->h_length);
  sa.sin_family = hostEntryPtr->h_addrtype;
  sa.sin_port = htons(port);

  s = socket(hostEntryPtr->h_addrtype, SOCK_STREAM, 0);
  if (-1 == s) {
    char        buf[300];

    sprintf(buf, "socket creation failed for \"%.*s\", %d", 256, hostName, port);
    mexErrMsgTxt(buf);
  }

  if (connect(s, (struct sockaddr *)&sa, sizeof(sa))) {
    char        buf[300];

    sprintf(buf, "connection failed for \"%.*s\", %d", 256, hostName, port);
    mexErrMsgTxt(buf);
  }


  {
    int one = 1;
    int val;

#if defined(_MSC_VER)
    if (setsockopt(s, IPPROTO_TCP, TCP_NODELAY, (char*)&one, sizeof(one))) {
      mexErrMsgTxt("failed to disable TCP delay");
    }
#else
    if (setsockopt(s, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one))) {
      mexErrMsgTxt("failed to disable TCP delay");
    }

    if ((val = fcntl(s, F_GETFD, 0)) < 0) {
      mexErrMsgTxt("failed to set socket close-on-exec: fcntl F_GETFD error");
    } else {
      val |= FD_CLOEXEC;
      if (fcntl(s, F_SETFD, val) < 0) {
        mexErrMsgTxt("failed to set socket close-on-exec: fcntl F_SETFD error");
      }
    }
#endif
  }


  /* null handshaking at the moment. */
  {
    char        buf[8];

    sendAll(s, "0000", 4);
    recvN(s, buf, 4);
    buf[4] = 0;
  }

  plhs[0] = mxCreateDoubleScalar((double) s);
}

/* args: op, sock */
static void doClose( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  int   s;

  if ((nrhs != 2) || !mxIsChar(prhs[0])) {
    mexErrMsgTxt("mex close expects: op (string), socket");
  }

  s = (int)mxGetScalar(prhs[1]);
  if (close(s)) mexErrMsgTxt("failed to close nws server connection");
}

/* args: op, sock, nws name, var name, mode */
static void doDeclare( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char          mode[ModeMaxLen];
  int           modeLen;
  char          nwsName[NwsNameMaxLen];
  int           nwsNameLen;
  char          *op = "declare var"; /* here and elsewhere, this is in
                                        a sense redundant, as the
                                        first rhs should have the same
                                        value. but nothing forces us
                                        to use the same string for
                                        denoting the operation when
                                        crossing the m-mex barrier and
                                        when communicating with the
                                        nws server. */
  int           s;
  char          varName[VarNameMaxLen];
  int           varNameLen;

  if ((nrhs != 5) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[2]) || !mxIsChar(prhs[3]) || !mxIsChar(prhs[4])) {
    mexErrMsgTxt("mex declare expects: op (string), socket, nws name (string), var name (string), mode (string)");
  }

  s = (int)mxGetScalar(prhs[1]);

  if (mxGetString(prhs[2], nwsName, sizeof(nwsName))) mexErrMsgTxt("NetWorkspace name string too long");
  nwsNameLen = strlen(nwsName);

  if (mxGetString(prhs[3], varName, sizeof(varName))) mexErrMsgTxt("variable name too long");
  varNameLen = strlen(varName);

  if (mxGetString(prhs[4], mode, sizeof(mode))) mexErrMsgTxt("mode too long");
  modeLen = strlen(mode);

  sendNumber(s, 4, 4);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);
  sendLB(s, 20, varNameLen, varName);
  sendLB(s, 20, modeLen, mode);

  /* read and check status. */
  {
    char        statusBuf[8];
    int         status;

    recvN(s, statusBuf, 4);
    statusBuf[4] = 0;

    status = atoi(statusBuf);
    if (status != 0)
      mexErrMsgTxt("declare failed");
  }
}

/* args: op, sock, nws name, var name */
static void doDeleteVar( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char          nwsName[NwsNameMaxLen];
  int           nwsNameLen;
  char          *op = "delete var";
  int           s;
  char          varName[VarNameMaxLen];
  int           varNameLen;

  if ((nrhs != 4) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[2]) || !mxIsChar(prhs[3])) {
    mexErrMsgTxt("mex delete expects: op (string), socket, nws name (string), var name (string)");
  }

  s = (int)mxGetScalar(prhs[1]);

  if (mxGetString(prhs[2], nwsName, sizeof(nwsName))) mexErrMsgTxt("NetWorkSpace name string too long");
  nwsNameLen = strlen(nwsName);

  if (mxGetString(prhs[3], varName, sizeof(varName))) mexErrMsgTxt("variable name too long");
  varNameLen = strlen(varName);

  sendNumber(s, 4, 3);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);
  sendLB(s, 20, varNameLen, varName);

  /* read and discard status. */
  {
    char        statusBuf[8];

    recvN(s, statusBuf, 4);
    statusBuf[4] = 0;
  }
}

/* args: op, sock, nws name */
static void doDeleteWs( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char          nwsName[NwsNameMaxLen];
  int           nwsNameLen;
  char          *op = "delete ws";
  int           s;

  if ((nrhs != 3) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[2])) {
    mexErrMsgTxt("mex delete ws expects: op (string), socket, nws name (string)");
  }

  s = (int)mxGetScalar(prhs[1]);

  if (mxGetString(prhs[2], nwsName, sizeof(nwsName))) mexErrMsgTxt("nws name string too long");
  nwsNameLen = strlen(nwsName);

  sendNumber(s, 4, 2);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);

  /* read and discard status. */
  {
    char        statusBuf[8];

    recvN(s, statusBuf, 4);
    statusBuf[4] = 0;
  }
}

/* args: op, sock, nwsName */
static void doListVars( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char  nwsName[NwsNameMaxLen];
  int   nwsNameLen;
  char  *op = "list vars";
  int   s;

  if ((3 != nrhs) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[2])) {
    mexErrMsgTxt("mex list vars expects: op (string), socket, nws name (string)");
  }

  s = (int)mxGetScalar(prhs[1]);

  if (mxGetString(prhs[2], nwsName, sizeof(nwsName))) mexErrMsgTxt("nws name too long");
  nwsNameLen = strlen(nwsName);

  sendNumber(s, 4, nrhs-1);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);

  /* read and discard status and desc info. */
  {
    char        dummy[24];

    recvN(s, dummy, 4);
    recvN(s, dummy, 20);
    dummy[20] = 0;
  }

  {
    char        *varList;
    int         varListLen;

    varList = recvLB(s, 20, &varListLen);
    if (varList) {
      plhs[0] = mxCreateString(varList);
      mxFree((void *) varList);
    }
    else {
      plhs[0] = mxCreateString("");
    }
  }
}

/* args: op, sock[, nwsName] */
static void doListWss( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char          *op = "list wss";
  int           s;

  if ((nrhs < 2) || (nrhs > 3) || !mxIsChar(prhs[0]) || ((nrhs == 3) && !mxIsChar(prhs[2]))) {
    mexErrMsgTxt("mex list wss expects: op (string), socket[, nws name (string)]");
  }

  s = (int)mxGetScalar(prhs[1]);

  sendNumber(s, 4, nrhs-1);
  sendLB(s, 20, strlen(op), op);

  if (3 == nrhs) {
    char        nwsName[NwsNameMaxLen];
    int         nwsNameLen;

    if (mxGetString(prhs[2], nwsName, sizeof(nwsName))) mexErrMsgTxt("nws name too long");
    nwsNameLen = strlen(nwsName);
    sendLB(s, 20, nwsNameLen, nwsName);
  }

  /* read and discard status and desc info. */
  {
    char        dummy[24];

    recvN(s, dummy, 4);
    recvN(s, dummy, 20);
    dummy[20] = 0;
  }

  {
    char        *setList;
    int         setListLen;

    setList = recvLB(s, 20, &setListLen);
    if (setList) {
      plhs[0] = mxCreateString(setList);
      mxFree((void *) setList);
    }
    else {
      plhs[0] = mxCreateString("");
    }
  }
}

/* args: op, sock, wsNameTemplate */
static void doMktempWs( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char  wnt[NwsNameMaxLen];
  char  *op = "mktemp ws";
  int   s;

  if ((nrhs != 3) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[2])) {
    mexErrMsgTxt("mex list workspaces expects: op (string), socket, ws name template (string)]");
  }

  s = (int)mxGetScalar(prhs[1]);

  sendNumber(s, 4, nrhs-1);
  sendLB(s, 20, strlen(op), op);

  if (mxGetString(prhs[2], wnt, sizeof(wnt))) mexErrMsgTxt("nws name too long");
  sendLB(s, 20, strlen(wnt), wnt);

  /* read status and desc info. */
  {
    char        statusBuf[8];
    char        descBuf[24];
    int         status;

    recvN(s, statusBuf, 4);
    recvN(s, descBuf, 20);
    statusBuf[4] = 0;
    descBuf[20] = 0;

    status = atoi(statusBuf);
    if (status != 0)
      mexErrMsgTxt("mktempWs failed");
  }


  /* get new name. */
  {
    char        *newName;
    int         newNameLen;

    newName = recvLB(s, 20, &newNameLen);
    if (newName) {
      plhs[0] = mxCreateString(newName);
      mxFree((void *) newName);
    }
    else {
      plhs[0] = mxCreateString("");
    }
  }
}

/* args: op, sock, nws name, persistent status */
static void doOpenWs( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char          nwsName[NwsNameMaxLen];
  int           nwsNameLen;
  char          ownerBuf[32];
  char          persistenceStatus[NwsNameMaxLen];
  int           persistenceStatusLen;
  char          *op = "open ws";
  int           s;

  sprintf(ownerBuf, "%d", getpid());

  if ((nrhs != 4) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[2]) || !mxIsChar(prhs[3])) {
    mexErrMsgTxt("mex open ws expects: op (string), socket, nws name (string), persistence status (string)");
  }

  s = (int)mxGetScalar(prhs[1]);

  if (mxGetString(prhs[2], nwsName, sizeof(nwsName)))
    mexErrMsgTxt("nws name string too long");
  nwsNameLen = strlen(nwsName);

  if (mxGetString(prhs[3], persistenceStatus, sizeof(persistenceStatus)))
    mexErrMsgTxt("persistence status too long");
  persistenceStatusLen = strlen(persistenceStatus);

  sendNumber(s, 4, 4);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);
  sendLB(s, 20, strlen(ownerBuf), ownerBuf);
  sendLB(s, 20, persistenceStatusLen, persistenceStatus);

  /* read and discard status */
  {
    char        statusBuf[8];
    int         status;

    recvN(s, statusBuf, 4);
    statusBuf[4] = 0;

    status = atoi(statusBuf);
    if (status != 0)
      mexErrMsgTxt("openWs failed");
  }
}


/* args: op, sock, nws name, persistent status */
static void doUseWs( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  char          nwsName[NwsNameMaxLen];
  int           nwsNameLen;
  char          *op = "use ws";
  int           s;
  char          *ownerBuf  = "";
  char          *persistenceStatus = "no";

  if ((nrhs != 3) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[2])) {
    mexErrMsgTxt("mex open ws expects: op (string), socket, nws name (string)");
  }

  s = (int)mxGetScalar(prhs[1]);

  if (mxGetString(prhs[2], nwsName, sizeof(nwsName)))
    mexErrMsgTxt("nws name string too long");
  nwsNameLen = strlen(nwsName);
  sendNumber(s, 4, 4);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);
  sendLB(s, 20, strlen(ownerBuf), ownerBuf);
  sendLB(s, 20, strlen(persistenceStatus), persistenceStatus);


  /* read and check status. */
  {
    char        statusBuf[8];
    int         status;

    recvN(s, statusBuf, 4);
    statusBuf[4] = 0;
    status = atoi(statusBuf);
    if (status != 0)
      mexErrMsgTxt("useWs failed");
  }
}

/*
  if blocking:
        rhs args: op, sock, nwsName, varName, opts
        lhs arg : value
  if non-blocking
        rhs args: op, sock, nwsName, varName, returnIfMissing, opts
        lhs args: value, present
*/

static void doRetrieve( int nlhs, mxArray *plhs[],
                        int nrhs, const mxArray *prhs[], int blockP, int removeP )
{
  int           s;
  int           i;
  int           n;
  char          nwsName[NwsNameMaxLen];
  int           nwsNameLen;
  char          op[OpMaxLen];
  int           opLen;
  char          varName[VarNameMaxLen];
  int           varNameLen;
  mxArray       *classIDArray = NULL;
  mxClassID     classID = -1;
  mxArray       *complexArray = NULL;
  int           complex = 0;
  mwSize        ndim;
  mxArray       *dimsArray = NULL;
  mwSize        dims[MaxDims];
  int           numElements = 0;

  if ((blockP && nrhs != 5) || (!blockP && nrhs != 6) ||
      !mxIsChar(prhs[0]) || !mxIsChar(prhs[2])|| !mxIsChar(prhs[3])) {
    mexErrMsgTxt("mex fetch/find expects: op (string), socket, nws name (string), var name (string)[, valueIfMissing when non-blocking] [opts (struct)]");
  }

  s = (int)mxGetScalar(prhs[1]);

  classIDArray = mxGetField(prhs[nrhs - 1], 0, "classid");
  if (classIDArray != NULL) {
    char classIDName[ClassIDNameMaxLen];
    if (mxGetString(classIDArray, classIDName, sizeof(classIDName)))
      mexErrMsgTxt("classid string too long");
    classID = getClassIDFromName(classIDName);
    if (debug) mexPrintf("debug: classid flag set to %s [%d]\n", classIDName, classID);
  }
  else {
    if (debug) mexPrintf("debug: no classid argument\n");
  }

  if (debug) mexPrintf("debug: checking for complex argument\n");

  complexArray = mxGetField(prhs[nrhs - 1], 0, "complex");
  if (complexArray != NULL) {
    complex = (int)mxGetScalar(complexArray);
    if (debug) mexPrintf("debug: complex flag set to %d\n", complex);
  }
  else {
    if (debug) mexPrintf("debug: no complex argument\n");
  }

  if (debug) mexPrintf("debug: checking for dims argument\n");

  dimsArray = mxGetField(prhs[nrhs - 1], 0, "dims");
  if (dimsArray != NULL) {
    if (debug) mexPrintf("debug: processing the dims argument\n");
    ndim = mxGetNumberOfElements(dimsArray);
    double *pr = mxGetPr(dimsArray);

    if (ndim > MaxDims)
      mexErrMsgTxt("too many dimensions specified");
    if (mxGetClassID(dimsArray) != mxDOUBLE_CLASS)
      mexErrMsgTxt("dims must be a double matrix");

    for (i = 0; i < MaxDims; i++) {
      dims[i] = 1;
    }

    numElements = 1;
    for (i = 0; i < ndim; i++) {
      dims[i] = (mwSize) *pr++;
      numElements *= dims[i];
      if (debug) mexPrintf("debug: dim = %d\n", dims[i]);
    }
  }
  else {
    if (debug) mexPrintf("debug: no dims argument\n");
  }

  if (mxGetString(prhs[0], op, sizeof(op)))
    mexErrMsgTxt("operation string too long");
  opLen = strlen(op);

  if (mxGetString(prhs[2], nwsName, sizeof(nwsName)))
    mexErrMsgTxt("nws name string too long");
  nwsNameLen = strlen(nwsName);

  if (mxGetString(prhs[3], varName, sizeof(varName)))
    mexErrMsgTxt("variable name too long");
  varNameLen = strlen(varName);

  sendNumber(s, 4, 3);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);
  sendLB(s, 20, varNameLen, varName);

  /* read the return value and discard status. */
  {
    unsigned int        desc;
    char                descBuf[24];
    char                *resultBuf = NULL;
    mxArray             *binData = NULL;
    char                resultLenBuf[32];
    int                 resultLen;
    char                statusBuf[8];
    int                 status;
    mwSize              n;

    recvN(s, statusBuf, 4);
    statusBuf[4] = 0;
    recvN(s, descBuf, 20);
    descBuf[20] = 0;
    sscanf(descBuf, "%u", &desc);

    recvN(s, resultLenBuf, 20);
    resultLenBuf[20] = 0;
    resultLen = atoi(resultLenBuf);

    /* XXX connection is corrupted if unable to alloc enough memory */
    if (resultLen > 0 || (desc & SerializationMask) == UnserializedData) {
      if ((desc & BinaryMask) == BinaryData) {
        /* the "classid" argument overrides desc */
        if (classID == -1) {
          classID = getClassID(desc);
        }

        /* the "complex" argument overrides desc */
        if (complexArray == NULL) {
          complex = (desc & BinaryComplexityMask) == BinaryComplex;
        }
        n = getNumberOfElements(classID, complex, resultLen);

        /* this is a bit of a hack... */
        if (n == 0 && resultLen > 0) {
          /* classID and complex are not compatible with resultLen */
          numElements = 0;
          n = resultLen;
          classID = mxUINT8_CLASS;
          complex = 0;
        }

        /* only use dims if it was specified and matches n */
        if (numElements != n) {
          if (numElements > 0) mexWarnMsgTxt("ignoring dims due to mismatch");

          /* initialize the dims array */
          for (i = 0; i < MaxDims; i++) {
            dims[i] = 1;
          }
          dims[0] = n;
          ndim = 2;
        }
        else {
          ndim = mxGetNumberOfElements(dimsArray);
        }

        if (debug) {
          if (complex)
            mexPrintf("creating %d dim complex matrix with %d elements\n", ndim, n);
          else
            mexPrintf("creating %d dim matrix with %d elements\n", ndim, n);
        }

        binData = mxCreateNumericArray(ndim, dims, classID,
            complex ? mxCOMPLEX : mxREAL);
        if (!binData) {
          mexErrMsgTxt("cannot allocate space for return value");
        }

        if (complex) {
          recvN(s, (char *) mxGetPr(binData), resultLen >> 1);
          recvN(s, (char *) mxGetPi(binData), resultLen >> 1);
        }
        else {
          recvN(s, (char *) mxGetData(binData), resultLen);
        }
      }
      else {
        resultBuf = (char *) mxMalloc(resultLen + 1);
        if (!resultBuf) {
          mexErrMsgTxt("cannot allocate space for return value");
        }
        recvN(s, resultBuf, resultLen);
        resultBuf[resultLen] = 0;
      }
    }

    /* check status */
    status = atoi(statusBuf);
    if (status != 0)
      mexErrMsgTxt("failed to retrieve value");

    if (blockP) {
      /* Must have an answer, but do we have an answer? */
      if ((desc & SerializationMask) == UnserializedData) {
        if ((desc & BinaryMask) == BinaryData)
          plhs[0] = binData;
        else
          plhs[0] = mxCreateString(resultBuf);
      }
      else if (resultLen > 0) {
        if ((desc & BabelMask) != MatlabFP) {
          mexErrMsgTxt("unable to deserialize object created by another language");
        }
        plhs[0] = mxDeserialize(resultBuf, resultLen);
      }
      else
        mexErrMsgTxt("retrieval of value failed");
    }
    else {
      plhs[1] = mxCreateLogicalMatrix(1, 1);
      if ((desc & SerializationMask) == UnserializedData) {
        *mxGetLogicals(plhs[1]) = 1;
        if ((desc & BinaryMask) == BinaryData)
          plhs[0] = binData;
        else
          plhs[0] = mxCreateString(resultBuf);
      }
      else if (resultLen > 0) {
        if ((desc & BabelMask) != MatlabFP) {
          mexErrMsgTxt("unable to deserialize object created by another language");
        }
        *mxGetLogicals(plhs[1]) = 1;
        plhs[0] = mxDeserialize(resultBuf, resultLen);
      }
      else {
        *mxGetLogicals(plhs[1]) = 0;
        plhs[0] = mxDuplicateArray(prhs[4]);
      }
    }
    if (resultBuf) mxFree((void *) resultBuf);
  }
}

/* args: op, sock, value, nws name, var name */
static void doStore( int nlhs, mxArray *plhs[],
                       int nrhs, const mxArray *prhs[] )
{
  unsigned int  desc;
  char          descTxt[24];
  char          nwsName[NwsNameMaxLen];
  int           nwsNameLen;
  char          *op = "store";
  int           s;
  int           raw;
  char          varName[VarNameMaxLen];
  int           varNameLen;

  if ((nrhs != 6) || !mxIsChar(prhs[0]) || !mxIsChar(prhs[3]) || !mxIsChar(prhs[4])) {
    mexErrMsgTxt("mex store expects: op (string), socket, val, nws name (string), var name (string), raw");
  }

  s = (int)mxGetScalar(prhs[1]);
  raw = (int)mxGetScalar(prhs[5]);

  desc = MatlabFP;

  if (mxIsUint8(prhs[2]) || raw) {
    mxClassID cid = mxGetClassID(prhs[2]);

    if (mxIsChar(prhs[2])) {
      /* handle strings properly if raw is specified */
      /* XXX is this right? */
      desc |= UnserializedData | StringData;
    }
    else if (mxIsSparse(prhs[2])) {
      mxErrMsgTxt("raw mode does not support sparse matrices");
    }
    else {
      desc |= UnserializedData | BinaryData;

      switch (cid) {
      case mxUINT8_CLASS:
        desc |= BinaryTypeUint | BinarySize8;
        break;
      case mxUINT16_CLASS:
        desc |= BinaryTypeUint | BinarySize16;
        break;
      case mxUINT32_CLASS:
        desc |= BinaryTypeUint | BinarySize32;
        break;
      case mxUINT64_CLASS:
        desc |= BinaryTypeUint | BinarySize64;
        break;
      case mxINT8_CLASS:
        desc |= BinaryTypeInt | BinarySize8;
        break;
      case mxINT16_CLASS:
        desc |= BinaryTypeInt | BinarySize16;
        break;
      case mxINT32_CLASS:
        desc |= BinaryTypeInt | BinarySize32;
        break;
      case mxINT64_CLASS:
        desc |= BinaryTypeInt | BinarySize64;
        break;
      case mxSINGLE_CLASS:
        desc |= BinaryTypeFP | BinarySize32;
        break;
      case mxDOUBLE_CLASS:
        desc |= BinaryTypeFP | BinarySize64;
        break;
      default:
        mexErrMsgTxt("unsupported raw type");
      }
    }
  } else if (mxIsChar(prhs[2])) {
    desc |= UnserializedData | StringData;
  }

  if (mxIsComplex(prhs[2]))
    desc |= BinaryComplex;

  sprintf(descTxt, "%020u", desc); /* More than enough to hold 2^32. */

  if (mxGetString(prhs[3], nwsName, sizeof(nwsName)))
    mexErrMsgTxt("nws name string too long");
  nwsNameLen = strlen(nwsName);

  if (mxGetString(prhs[4], varName, sizeof(varName)))
    mexErrMsgTxt("variable name too long");
  varNameLen = strlen(varName);


  sendNumber(s, 4, 5);
  sendLB(s, 20, strlen(op), op);
  sendLB(s, 20, nwsNameLen, nwsName);
  sendLB(s, 20, varNameLen, varName);
  sendLB(s, 20, 20, descTxt);

  if ((desc & SerializationMask) == UnserializedData) {
    int dataLen = mxGetNumberOfElements(prhs[2]);
    int esize = mxGetElementSize(prhs[2]);
    int len = dataLen * esize;

    if ((desc & BinaryMask) == BinaryData) {
      if (mxIsComplex(prhs[2])) {
        sendNumber(s, 20, len * 2);
        sendAll(s, (char *) mxGetPr(prhs[2]), len);
        sendAll(s, (char *) mxGetPi(prhs[2]), len);
      }
      else {
        sendLB(s, 20, len, (char *) mxGetData(prhs[2]));
      }
    }
    else {
      char      *buf = (char *) mxMalloc(dataLen + 1);

      mxGetString(prhs[2], buf, dataLen + 1);
      sendLB(s, 20, dataLen, buf);
      mxFree((void *) buf);
    }
  }
  else {
    /* serialize the value. */
    mxArray     *pickle = mxSerialize(prhs[2]);
    int         pickleLen = mxGetNumberOfElements(pickle);

    sendLB(s, 20, pickleLen, (char *) mxGetData(pickle));
    if (pickle) mxDestroyArray(pickle);
  }

  /* read and check status. */
  {
    char        statusBuf[8];
    int         status;

    recvN(s, statusBuf, 4);
    statusBuf[4] = 0;

    status = atoi(statusBuf);
    if (status != 0)
      mexErrMsgTxt("store failed");
  }
}

/*  dispatch routine.  */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
  char  cmd[128];

  if (0 == nrhs) {
    mexErrMsgTxt("You gotta give me something to work with here ...");
  }

  if (mxGetM(prhs[0])*mxGetN(prhs[0]) >= sizeof(cmd)) {
    mexErrMsgTxt("Command too long");
  }
  mxGetString(prhs[0], cmd, sizeof(cmd));

  if (!strcasecmp(cmd, "close")) {
    doClose(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "connect")) {
    doConnect(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "declare var")) {
    doDeclare(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "delete var")) {
    doDeleteVar(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "delete ws")) {
    doDeleteWs(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "debug")) {
    if (nrhs > 1)
      debug = (int)mxGetScalar(prhs[1]);
    else
      debug = !debug;
  }
  else if (!strcasecmp(cmd, "fetch")) {
    doRetrieve(nlhs, plhs, nrhs, prhs, 1, 1);
  }
  else if (!strcasecmp(cmd, "fetchTry")) {
    doRetrieve(nlhs, plhs, nrhs, prhs, 0, 1);
  }
  else if (!strcasecmp(cmd, "find")) {
    doRetrieve(nlhs, plhs, nrhs, prhs, 1, 0);
  }
  else if (!strcasecmp(cmd, "findTry")) {
    doRetrieve(nlhs, plhs, nrhs, prhs, 0, 0);
  }
  else if (!strcasecmp(cmd, "list vars")) {
    doListVars(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "list wss")) {
    doListWss(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "mktemp ws")) {
    doMktempWs(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "use ws")) {
    doUseWs(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "open ws")) {
    doOpenWs(nlhs, plhs, nrhs, prhs);
  }
  else if (!strcasecmp(cmd, "store")) {
    doStore(nlhs, plhs, nrhs, prhs);
  }
  else
    mexErrMsgTxt("Unrecognized command");
}
