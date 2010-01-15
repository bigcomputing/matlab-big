function X = listWss(nwss)
% LISTWSS  lists all netWorkSpaces in nwsServer, nwss.
%
% X = listWss(nwss) returns a struct array listing
% information about all the netWorkSpaces currently available
% on the server reached by connection nwss.
%
% If no left hand side, print a tabular listing.
%
% Arguments:
% nwss -- nwsServer class object.

% Copyright 2006-2008 REvolution Computing, Inc.
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%

wsList = nwsMex('list wss', nwss.s);

if nargout == 0
  if length(wsList) > 0
    fprintf('Name\tOwner\tPersistent\t#Vars\tVars\n');
    fprintf('%s\n', wsList);
  else
    fprintf('No netWorkSpace %s.\n', netWorkSpaceName);
  end
else
  if length(wsList) > 0
    wsStructs = struct([]);
    newLine = sprintf('\n');
    tab = sprintf('\t');
    lines = unique([0, strfind(wsList, newLine) length(wsList)]);

    for x = 2:(length(lines))
      % starts at position 2. The first character indicates
      % if caller owns the workspace
      l = wsList(lines(x-1)+2:lines(x));
      c = wsList(lines(x-1)+1:lines(x-1)+1);

      fields{1} = strcmp(c, '>');

      fields_pos = unique([0, strfind(l, tab), length(l)]);

      for c = 2:length(fields_pos)
        end_pos = fields_pos(c);
        % exclude tab in the string
        if end_pos ~= length(l)
          end_pos = end_pos - 1;
        end
        fields{c} = l(fields_pos(c-1)+1:end_pos);
      end
      wsStructs = [wsStructs, struct('owned', fields{1}, ...
                                     'name', fields{2}, ...
                                     'owner', fields{3}, ...
                                     'persistent', fields{4}, ...
                                     'numVariables', eval(fields{5}), ...
                                     'variables', fields{6})];
    end
    X = wsStructs;
  else
    X = [];
  end
end
