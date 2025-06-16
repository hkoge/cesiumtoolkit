c --------------------------
c    wsmag2split
c -------------------------
	parameter(idm=1000000)
	implicit real*8(a-h,o-z)
	integer*4 it(6),no(1000),iy(idm)
	real*8 dy(idm),at(idm),an(idm),am(idm)
c
 1000   format(i4,i5,2i2,1x,3i2,2f11.5,f10.2)
 2000   format(i5,i6,i5,f12.7,2f11.5,f10.2)
	dlmt =0.05d0
	dpl  =1.0d0
c---------------
	ln0=0
	k =1
	kk=1
	nn=0
	i =0
   10   i =i+1
      read(5,1000,end=20) ln,it,an(i),at(i),am(i)
c
	iy(i)   =it(1)
	dy(i)   =ymdhms2dy(it)
c	      write(6,2000) dy(i),an(i),at(i),am(i),et(i),nn
	if (i.eq.1) then
	   ln0=ln
	   go to 10
	endif
	if (ln.ne.ln0) go to 30
	ddy =dy(i)-dy(i-1)
	if (iy(i).gt.iy(i-1)) then
	  if (mod(iy(i-1),4).eq.0) then
	     ddy =ddy+366.d0
	  else
	     ddy =ddy+365.d0
	  endif
	endif
	if (ddy.gt.dlmt) go to 30
	go to 10
c
   20   kk =0
   30   ie =i-1
	in =1
	ne =ie
	   if (ne-in.lt.4) then
		      do ii=in,ne
	      write(6,2000) ln0,0,iy(ii),dy(ii),an(ii),at(ii),am(ii)
		      end do
	      if (kk.eq.0) go to 90
	      iy(1) =iy(ie+1)
	      dy(1) =dy(ie+1)
	      at(1) =at(ie+1)
	      an(1) =an(ie+1)
	      am(1) =am(ie+1)
	      i     =1
	      k     =1
	      if (ln0.ne.ln) then
		 nn =0
		 ln0=ln
	      endif
	      go to 10
	   endif
	no(1)=ne+1
c	ln0=ln
   40   continue
	dp0 =distpline(at(in),an(in),at(ne),an(ne),at(in+1),an(in+1))
	      in0 =in+1
	do i=in+2,ne-1
	   dp =distpline(at(in),an(in),at(ne),an(ne),at(i),an(i))
	   if (dp.gt.dp0) then
	      in0 =i
	      dp0 =dp
	   endif
	end do
c	write(6,*) 2,k,in,ne
	if (dp0.lt.dpl) then
c	   nn =nn+1
           call vectorline(at(in),an(in),at(ne),an(ne),dln,dlt)
	   do i=in,ne-1
              call vectorline(at(i),an(i),at(i+1),an(i+1),aln,alt)
	      if (aln*dln+alt*dlt.lt.0.d0) then
		 is =-1
	      else
		 is =1
	      endif
	      if (i.eq.in) then
		 is0 =is
		 ii  =0
		 i1  =in
	      else
		iss =is0*is
	        if (iss.lt.0) then
	           if (ii.gt.5) then
		      nn =nn+1
c	write(6,*) 7,k,i1,i
		      do ii=i1,i
	      write(6,2000) ln0,nn,iy(ii),dy(ii),an(ii),at(ii),am(ii)
		      end do
		   else
		      do ii=i1,i
	      write(6,2000) ln0,0,iy(ii),dy(ii),an(ii),at(ii),am(ii)
		      end do
		   endif
		      is0=is
		   ii =0
		   i1 =i+1
		else
		   ii =ii+1
		endif
	      endif
	   end do
		if (ii.gt.5) then
		   nn =nn+1
c	write(6,*) 6,k,i1,ne
		   do ii=i1,ne
	      write(6,2000) ln0,nn,iy(ii),dy(ii),an(ii),at(ii),am(ii)
		   end do
		else
		   do ii=i1,ne
	      write(6,2000) ln0,0,iy(ii),dy(ii),an(ii),at(ii),am(ii)
		   end do
		endif
c	write(6,*) 3,k,in,ne
	   if (ne.eq.ie) then
	      if (kk.eq.0) go to 90
	      iy(1) =iy(ie+1)
	      dy(1) =dy(ie+1)
	      at(1) =at(ie+1)
	      an(1) =an(ie+1)
	      am(1) =am(ie+1)
	      i     =1
	      k     =1
	      if (ln0.ne.ln) then
		 nn =0
		 ln0=ln
	      endif
	      go to 10
	   else
	      in =ne+1
	      k  =k-1
	      ne =no(k)-1
	if (k.eq.0) stop
	   endif
	elseif (in0-in.lt.4) then
	    if (in0-in.gt.0) then
		      do ii=in,in0-1
	      write(6,2000) ln0,0,iy(ii),dy(ii),an(ii),at(ii),am(ii)
		      end do
	    endif
	      in =in0
c	write(6,*) 5,k,in,ne
	else
	   k     =k+1
	   no(k) =in0
	   ne    =no(k)-1
c	write(6,*) 4,k,in,ne
	endif
	   go to 40
c
	
   90   stop
	end
C-------------------------------------------------------------------
C   Function for calculating time in days   from YYYY,MM,DD,HH,MM,SS
c     Julian day - 1 used
C-------------------------------------------------------------------
      FUNCTION ymdhms2dy(it)
      implicit real*8(a-h,o-z)
      integer*4 it(6)
c
      jd        = jlday(it(1),it(2),it(3))
      ymdhms2dy = dble(jd-1) + dble(it(4)*3600+it(5)*60+it(6))/86400.d0
      RETURN
      END
c--------------------------
c	function to calculate (dln,dlt) from two (lat, long) pairs
c	cos(lat) included in dln 
c--------------------------
      subroutine vectorline(flt1,fln1,flt2,fln2,dln,dlt)
	implicit real*8(a-h,o-z)
        data  fact/1.745329251994d-2/
c
	clt =dcos((flt2+flt1)*fact*.5d0)
	dlt =flt2-flt1
	dln =(fln2-fln1)*clt
	return
	end
c--------------------------
c	function to calculate distance in km from point (a,b) to line (x1,y1) - (x2, y2)
c--------------------------
      function distpline(flt1,fln1,flt2,fln2,flt,fln)
	implicit real*8(a-h,o-z)
        data  fact2/55.56d0/
c
        call vectorline(flt1,fln1,flt2,fln2,dln,dlt)
	r2  =dlt*dlt+dln*dln
        call vectorline(flt1,fln1,flt,fln,dln,dlt)
	p2  =dlt*dlt+dln*dln
        call vectorline(flt2,fln2,flt,fln,dln,dlt)
	q2  =dlt*dlt+dln*dln
	pqr =(p2+q2-r2)**2
	distpline =dsqrt(4.d0*p2*q2-pqr)/dsqrt(r2)*fact2
	return
	end
c-----------------------------------------------------------------------
c   Conversion from month+day to Julian day
c-----------------------------------------------------------------------
        function jlday(iyr,mon,iday)
        implicit none
        integer*4 kday(12),iyr,mon,iday,jlday
        data kday/0,31,59,90,120,151,181,212,243,273,304,334/
        if (mon.le.0.or.mon.ge.13) then
           jlday =999
        else
           jlday = kday(mon)+iday
           if (mod(iyr,4).eq.0.and.mon.ge.3) jlday = jlday+1
        endif
        return
        end
