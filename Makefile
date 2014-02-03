
xrdfragcp: xrdfragcp.cxx
	${CXX} -o $@ -I/usr/include/xrootd -L/usr/lib64 -lXrdClient -lXrdCl -lpcrecpp -pthread $<

xrdfragcpnew: xrdfragcpnew.cxx
	${CXX} -o $@ -I/home/alja/xrd/bld/ixrd/include/xrootd -L/home/alja/xrd/bld/ixrd/lib64  -lXrdCl -lXrdUtils -lpcrecpp -pthread $<

hdtools.jar: hdtools/HadoopTools.java
	javac -classpath '/usr/lib/hadoop-0.20/*:/usr/lib/hadoop-0.20/lib/*' $<
	jar cvfm $@ hdtools/Manifest.txt hdtools  

clean:
	rm -rf xrdfragcp
