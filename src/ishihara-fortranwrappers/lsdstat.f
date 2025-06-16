c
	implicit real*8(a-h,o-z)
	ln0=0
	no0=0
	nr =0
	write(6,1000)
   10 read(5,*,end=90) ln,no,iy,dy,aln,alt,an,ds
	nr =nr+1
	if (no.eq.0) go to 10
	if (ln.ne.ln0.or.no.ne.no0) then
	   if (ln0.ne.0) then
	      dln =aln2-aln1
	      if (dln.gt.180.d0) then
		dln =dln-360.d0
		aln2=aln2-360.d0
	      elseif (dln.lt.-180.d0) then
		dln =dln+360.d0
		aln2=aln2+360.d0
	      endif
	      dlt =alt2-alt1
	      ddy =dy2-dy1
	      if (iy2.ne.iy1) then
	         if (mod(iy1,4).eq.0) then
		   ddy =ddy+366.d0
	         else
		   ddy =ddy+365.d0
	         endif
	      endif
	      call elpdistll(alt1,aln1,alt2,aln2,dst,head)
	      write(6,2000) ln0,no0,nr1,nr2,iy1,dy1,dy2,ddy,
     .         aln1,aln2,dln,alt1,alt2,dlt,dst,head
	   endif
	   ln0 =ln
	   no0 =no
	   iy1 =iy
	   dy1 =dy
	   aln1=aln
	   alt1=alt
	   nr1 =nr
	else
	   iy2 =iy
	   dy2 =dy
	   aln2=aln
	   alt2=alt
	   nr2 =nr
	endif
	go to 10
c
   90	   call elpdistll(alt1,aln1,alt2,aln2,dst,head)
	   write(6,2000) ln0,no0,nr1,nr2,iy1,dy1,dy2,ddy,
     .      aln1,aln2,dln,alt1,alt2,dlt,dst,head
      stop
 1000 format('Cruise Line   Rec #1   Rec #2 Year Day1',8x,'Day2',
     .       10x,'Diff.',5x,'Longitude 1 Longitude 2  Diff.',4x,
     .     'Latitude 1  Latitude 2  Diff.    Distance   Heading'/)
 2000 format(i5,i6,2i9,i5,3f12.7,6f11.5,f12.4,f8.2)
      end
c-------------------------------------------------------------------
C     DISTHEADLL
c        Distance & heading of two geographic points
c	   input:  lat & long of 2 points in degrees
c	   output: distance in km & heading clockwise from N in degrees
c	 Spherical approximation
c 
c-------------------------------------------------------------------
c	subroutine distheadll(flt0,fln0,flt,fln,dist,head)
c	implicit real*8(a-h,o-z)
c	data  fact,fact2/1.745329251994d-2,1.569681852679d-4/
c
c	if (fln.lt.0.d0) fln =fln+360.d0
c       alt = flt*fact
c       alt0= flt0*fact
c	clt = dcos(alt)
c	slt = dsin(alt)
c	clt0= dcos(alt0)
c	slt0= dsin(alt0)
c
c	dlon =(fln-fln0)*fact
c	cdlon=dcos(dlon)
c	cosc  =slt*slt0+clt*clt0*cdlon
c	if (cosc.ge.1.d0) then
c	   dist =0.d0
c	   head =0.d0
c	else
c	   dll  =dacos(cosc)
c	   dist =dll/fact2
c	   sdlon=dsin(dlon)
c	   sdll =dsin(dll)
c	   head =dasin(sdlon*clt/sdll)/fact
c	   if (flt.lt.flt0) head =180.d0-head
c	   if (head.lt.0.d0) head=head+360.d0
c	endif
c	return
c	end
c-------------------------------------------------------------------
C     ELPDISTLL
c        Distance of two geographic points on a ellipsoid earth
c	   input:  lat & long of 2 points in degrees
c	   output: distance in km
c	 Ellipsoid approximation
c 
c-------------------------------------------------------------------
	subroutine elpdistll(flt0,fln0,flt,fln,dist,head)
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
	cltm=(clt+clt0)*.5d0
c
	dlat  =flt-flt0
	dlon  =fln-fln0
	cdlon =dcos(dlon*fact)
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
	dist=a*x-a0*p-b0*q
	head=datan2(dlon*cltm,dlat)/fact
	if (head.lt.0.d0) head=head+360.d0
	return
	end

