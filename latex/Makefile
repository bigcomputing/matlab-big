TARGETS = nwsMATLAB.pdf
SOURCE = nwsMATLAB.tex intro.tex getting_started.tex  nws_tutorial.tex  sleigh_tutorial.tex \
    netWorkSpace_doc.tex nwsServer_doc.tex sleigh_doc.tex sleighPending_doc.tex \
    ssh_configuration.tex webinterface.eps

all: $(TARGETS)

nwsMATLAB.pdf: $(SOURCE)
	latex nwsMATLAB.tex
	latex nwsMATLAB.tex
	dvipdf nwsMATLAB.dvi

clean:
	-@/bin/rm -f $(TARGETS) *.aux *.dvi *.idx *.log *.out *.toc
