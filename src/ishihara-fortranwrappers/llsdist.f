c
	implicit real*8(a-h,o-z)
   10 read(5,*,end=90) ln,no,iy,dy,aln,alt,an
	if (alt.lt.-59.d0) then
	   if (aln.gt.286.d0) then
	      aln =aln-360.d0
	   elseif(aln.lt.-74.d0) then
	      aln =aln+360.d0
	   endif
 	elseif (alt.lt.-54.d0) then
	   if (5.d0*(aln-286.d0).gt.4.5d0*(alt+59.d0)) then
	      aln =aln-360.d0
	   elseif (5.d0*(aln+74.d0).lt.4.5d0*(alt+59.d0)) then
	      aln =aln+360.d0
	   endif
	elseif (alt.lt.-30.d0) then
	   if (aln.gt.290.5d0) then
	      aln =aln-360.d0
	   elseif(aln.lt.-69.5d0) then
	      aln =aln+360.d0
	   endif
 	elseif (alt.lt.8.d0) then
	   if (aln.gt.283.d0) then
	      aln =aln-360.d0
	   elseif(aln.lt.-77.d0) then
	      aln =aln+360.d0
	   endif
 	elseif (alt.lt.9.d0) then
	   if (aln+alt.gt.291.d0) then
	      aln =aln-360.d0
	   elseif (aln+alt.lt.-69.d0) then
	      aln =aln+360.d0
	   endif
	elseif (alt.lt.20.d0) then
	   if (11.d0*(aln-262.d0).gt.-16.d0*(alt-20.d0)) then
	      aln =aln-360.d0
	   elseif (11.d0*(aln+98.d0).lt.-16.d0*(alt-20.d0)) then
	      aln =aln+360.d0
	   endif
	else
	   if (aln.gt.262.d0) then
	      aln =aln-360.d0
	   elseif (aln.lt.-98.d0) then
	      aln =aln+360.d0
	   endif
	endif
	if (no.eq.0) then  
	   write(6,2000) ln,no,iy,dy,aln,alt,an,ds0
	   go to 10
	elseif (ln.eq.ln0.and.no.eq.no0) then
	   if (alt.eq.alt0.and.aln.eq.aln0) go to 10
	   ds =ds+elpdistll(alt0,aln0,alt,aln)
	else
	   ds =0.d0
	   ln0=ln
	   no0=no
	endif
	write(6,2000) ln,no,iy,dy,aln,alt,an,ds
	alt0 =alt
	aln0 =aln
	go to 10
c
   90 stop
 2000 format(i5,i6,i5,f12.7,2f11.5,f10.2,f10.2)
      end
c-------------------------------------------------------------------
C     ELPDISTLL
c        Distance of two geographic points on a ellipsoid earth
c	   input:  lat & long of 2 points in degrees
c	   output: distance in km
c	 Ellipsoid approximation
c 
c-------------------------------------------------------------------
	function elpdistll(flt0,fln0,flt,fln)
	implicit real*8(a-h,o-z)
	data  fact,fact2/1.745329251994d-2,1.569681852679d-4/
	data  a,b/6378.137d0,6356.752d0/
	ratio =b/a
	difab =a-b
c
c	if (fln.lt.0.d0) fln =fln+360.d0
        alt = datan(atan(flt*fact)*ratio)
        alt0= datan(atan(flt0*fact)*ratio)
	clt = dcos(alt)
	slt = dsin(alt)
	clt0= dcos(alt0)
	slt0= dsin(alt0)
c
	cdlon =dcos((fln-fln0)*fact)
	cosc  =slt*slt0+clt*clt0*cdlon
	if (cosc.ge.1.d0) then
	   x =0.d0
	else
	   x =dacos(cosc)
	endif
	xa   =x*fact
c
	a0  = (slt+slt0)**2
	b0  = (slt-slt0)**2
	sx  =dsin(x)
	cx  =dcos(x)
	p   =difab*(x-sx)/(1.d0+cx)*.25d0
	q   =difab*(x+sx)/(1.d0-cx)*.25d0
	elpdistll =a*x-a0*p-b0*q
	return
	end

