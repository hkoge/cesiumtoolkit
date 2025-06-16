c --------------------------
c    LLFIND
c -------------------------
	parameter(idm=40000000,ndm=500000)
	implicit real*8(a-h,o-z)
	integer*4 ln(ndm),no(ndm),nr1(ndm),nr(ndm),iy(ndm)
	real*8 dy1(ndm),dy2(ndm),aln1(ndm),aln2(ndm),alt1(ndm),alt2(ndm)
	real*8 hd(ndm),aln(idm),alt(idm),ds(idm),dt(ndm)
	character*50 fl1,fl2
	common nr1,nr,ds,alt,aln
	dtw = 15.d0/109.d0
	fact=1.745329251994d-2*.5d0
c
 2000   format(2(i5,i5,2f12.4),f10.2)
c2000   format(2(i5,i5,2f12.4),f10.2,i3)
c
c---- llsd file
	read(5,'(a50)') fl1
	open(10,file=fl1)
	i =1
   10   read(10,*,end=20) ln0,no0,iy0,dy0,aln(i),alt(i),an,ds(i)
	i =i+1
	go to 10
c
   20   ie=i-1
	close(10)
c---- stat file
	read(5,'(a50)') fl2
	open(20,file=fl2)
	read(20,'(60x)')
	read(20,'(60x)')
	i =1
   30   read(20,*,end=40) ln(i),no(i),nr1(i),nr2,iy(i),dy1(i),dy2(i),
     .         ddy,aln1(i),aln2(i),dln,alt1(i),alt2(i),dlt,dt(i),hd(i)
	nr(i) =nr2-nr1(i)
	i =i+1
	go to 30

   40	ne =i-1 
	do n=1,ne-2
c	if (ln(n).ne.442.or.no(n).ne.7) go to 60
c	if (ln(n).ne.311.or.no(n).ne.17) go to 60
c	if (ln(n).ne.373.or.no(n).ne.25) go to 60
c	if (ln(n).ne.380.or.no(n).ne.143) go to 60
	   dnw =dtw/dcos((alt1(n)+alt2(n))*fact)
	   if (alt1(n).lt.alt2(n)) then
	      blt1=alt1(n)-dtw
	      blt2=alt2(n)+dtw
	   else
	      blt1=alt2(n)-dtw
	      blt2=alt1(n)+dtw
	   endif
	   if (aln1(n).lt.aln2(n)) then
	      bln1=aln1(n)-dnw
	      bln2=aln2(n)+dnw
	   else
	      bln1=aln2(n)-dnw
	      bln2=aln1(n)+dnw
	   endif
	   do m=n+2,ne
c 	if (ln(m).ne.1830.or.(no(m).lt.4.or.no(m).gt.5)) go to 50
	      flt1=dmin1(alt1(m),alt2(m))
	      flt2=dmax1(alt1(m),alt2(m))
	      if (flt1.gt.blt2.or.flt2.lt.blt1) go to 50
	      fln1=dmin1(aln1(m),aln2(m))
	      fln2=dmax1(aln1(m),aln2(m))
	      if (fln1.gt.bln2.or.fln2.lt.bln1) go to 50
c
	      fln1=aln1(n)
	      fln2=aln2(n)
	      flt1=alt1(n)
	      flt2=alt2(n)
	      fln3=aln1(m)
	      fln4=aln2(m)
	      flt3=alt1(m)
	      flt4=alt2(m)
	      ns1 =0
	      ns2 =0
	      ns3 =0
	      ns4 =0
	      dhd =dabs(hd(m)-hd(n))
	   if (dhd.lt.5.d0.or.dhd.gt.355.d0.or.
     .        (dhd.gt.175.d0.and.dhd.lt.185.d0)) then
	      call distpline(flt1,fln1,flt2,fln2,flt3,fln3,ds0,ra,rb)
	      ds2 =0.d0
	      an2 =0.d0
	      if (ra.ge.0.d0.and.rb.ge.0.d0) then
		ns1 =1
		if (ds0.le.15.d0) then
		   ds1 =dt(n)*ra/(ra+rb)
		   an1 =ann1(n,ds1)
                   write(6,2000) ln(n),no(n),ds1,an1,
     .				 ln(m),no(m),ds2,an2,ds0
		endif
	      endif
	      call distpline(flt3,fln3,flt4,fln4,flt1,fln1,ds0,ra,rb)
	      ds1 =0.d0
	      an1 =0.d0
	      if (ra.ge.0.d0.and.rb.ge.0.d0) then
		ns2 =1
		if (ds0.le.15.d0) then
		   ds2 =dt(m)*ra/(ra+rb)
		   an2 =ann1(m,ds2)
		   write(6,2000) ln(n),no(n),ds1,an1,
     .				 ln(m),no(m),ds2,an2,ds0
		endif
	      endif
	      call distpline(flt1,fln1,flt2,fln2,flt4,fln4,ds0,ra,rb)
	      ds2 =dt(m)
	      an2 =nr(m)
	      if (ra.ge.0.d0.and.rb.ge.0.d0) then
		ns3 =1
		if (ds0.le.15.d0) then
		   ds1 =dt(n)*ra/(ra+rb)
		   an1 =ann1(n,ds1)
		   write(6,2000) ln(n),no(n),ds1,an1,
     .				 ln(m),no(m),ds2,an2,ds0
		endif
	      endif
	      call distpline(flt3,fln3,flt4,fln4,flt2,fln2,ds0,ra,rb)
	      ds1 =dt(n)
	      an1 =nr(n)
	      if (ra.ge.0.d0.and.rb.ge.0.d0) then
		ns4 =1
		if (ds0.le.15.d0) then
		   ds2 =dt(m)*ra/(ra+rb)
		   an2 =ann1(m,ds2)
		   write(6,2000) ln(n),no(n),ds1,an1,
     .				 ln(m),no(m),ds2,an2,ds0
		endif
	      endif
	      if (dhd.lt.5.d0.or.dhd.gt.355.d0) then
		if (ns1.eq.0.and.ns2.eq.0) then
		   ds0 =dsqrt(distline2(flt1,fln1,flt3,fln3))*111.12d0
		   if (ds0.le.15.d0) then
		      ds1 =0.d0
		      ds2 =0.d0
	      	      an1 =0.d0
	      	      an2 =0.d0
		      write(6,2000) ln(n),no(n),ds1,an1,
     .				    ln(m),no(m),ds2,an2,ds0
		   endif
		endif
		if (ns3.eq.0.and.ns4.eq.0) then
		   ns0 =dsqrt(distline2(flt2,fln2,flt4,fln4))*111.12d0
		   if (ds0.le.15.d0) then
		      ds1 =dt(n)
		      ds2 =dt(m)
	      	      an1 =nr(n)
	      	      an2 =nr(m)
		      write(6,2000) ln(n),no(n),ds1,an1,
     .				    ln(m),no(m),ds2,an2,ds0
		   endif
		endif
	      elseif (dhd.gt.175.d0.and.dhd.lt.185.d0)then
		if (ns1.eq.0.and.ns4.eq.0) then
		   ds0 =dsqrt(distline2(flt2,fln2,flt3,fln3))*111.12d0
		   if (ds0.le.15.d0) then
		      ds1 =dt(n)
		      ds2 =0.d0
	      	      an1 =nr(n)
	      	      an2 =0.d0
		      write(6,2000) ln(n),no(n),ds1,an1,
     .				    ln(m),no(m),ds2,an2,ds0
		   endif
		endif
		if (ns2.eq.0.and.ns3.eq.0) then
		   ns0 =dsqrt(distline2(flt1,fln1,flt4,fln4))*111.12d0
		   if (ds0.le.15.d0) then
		      ds1 =0.d0
		      ds2 =dt(m)
	      	      an1 =0.d0
	      	      an2 =nr(m)
		      write(6,2000) ln(n),no(n),ds1,an1,
     .				    ln(m),no(m),ds2,an2,ds0
		   endif
		endif
	      endif
	      call xycross(aln1(n),alt1(n),aln2(n),alt2(n),
     .                  aln1(m),alt1(m),aln2(m),alt2(m),t,u)
	      if (t.le.1.d0.and.t.ge.0.d0.and.u.ge.0.d0.and.u.le.1.d0)
     .        then
	         ds1 =dt(n)*t
	         ds2 =dt(m)*u
	         call ann2(n,ds1,m,ds2,t,u)
		 if (t.ne.9999.d0.and.u.ne.9999.d0) then
	            ds0 =0.d0
	            write(6,2000) ln(n),no(n),ds1,t,
     .			          ln(m),no(m),ds2,u,ds0
		 endif
	      endif
	   else
	      call xycross(aln1(n),alt1(n),aln2(n),alt2(n),
     .                  aln1(m),alt1(m),aln2(m),alt2(m),t,u)
	      if (t.le.1.d0.and.t.ge.0.d0.and.u.ge.0.d0.and.u.le.1.d0)
     .           then
	         ds1 =dt(n)*t
	         ds2 =dt(m)*u
	         call ann2(n,ds1,m,ds2,t,u)
		 if (t.ne.9999.d0.and.u.ne.9999.d0) then
	            ds0 =0.d0
	            write(6,2000) ln(n),no(n),ds1,t,
     .			          ln(m),no(m),ds2,u,ds0
		    go to 50
		 endif
	      endif
		if (u.gt.0.d0.and.u.lt.1.d0.and.t.ne.9999.d0) then
		   ds01=9999.d0
		else
		   if (u.le.0.d0) then
		      x2 =aln1(m)
		      y2 =alt1(m)
		      ds2=0.d0
	      	      an2=0.d0
		   elseif (u.ge.1.d0) then
		      x2 =aln2(m)
		      y2 =alt2(m)
		      ds2=dt(m)
	      	      an2 =nr(m)
		   endif
		   call distpline(flt1,fln1,flt2,fln2,y2,x2,ds0,ra,rb)
c	write(6,*) no(m),flt1,fln1,flt2,fln2,y2,x2
c	write(6,*) no(m),t,u,ra,rb
		   if (ra.ge.0.d0.and.rb.ge.0.d0) then
		      x1 =fln1+(fln2-fln1)*ra/(ra+rb)
		      y1 =flt1+(flt2-flt1)*ra/(ra+rb)
		      if (ds0.le.15.d0) then
			ds1 =dt(n)*ra/(ra+rb)
		        an1 =ann1(n,ds1)
		        write(6,2000) ln(n),no(n),ds1,an1,
     .				      ln(m),no(m),ds2,an2,ds0
		      endif
		      go to 50
		   endif
		   if (ra.le.0.d0) then
		      x1 =fln1
		      y1 =flt1
		      ds1=0.d0
	      	      an1 =0.d0
		   elseif (rb.le.0.d0) then
		      x1 =fln2
		      y1 =flt2
		      ds1=dt(n)
	      	      an1 =nr(n)
		   endif
		   ds01=dsqrt(distline2(y1,x1,y2,x2))*111.12d0
		endif
		if (t.gt.0.d0.and.t.lt.1.d0.and.u.ne.9999.d0) then
		   ds02=9999.d0
		else
		   if (t.le.0.d0) then
		      x4 =aln1(n)
		      y4 =alt1(n)
		      ds3=0.d0
	      	      an3 =0.d0
		   elseif (t.ge.1.d0) then
		      x4 =aln2(n)
		      y4 =alt2(n)
		      ds3=dt(n)
	      	      an3 =nr(n)
		   endif
		   call distpline(flt3,fln3,flt4,fln4,y4,x4,ds0,rc,rd)
c	write(6,*) no(m),rc,rd
		   if (rc.ge.0.d0.and.rd.ge.0.d0) then
		      x3 =fln3+(fln4-fln3)*rc/(rc+rd)
		      y3 =flt3+(flt4-flt3)*rc/(rc+rd)
		      if (ds0.le.15.d0) then
			ds4 =dt(m)*rc/(rc+rd)
		        an4 =ann1(m,ds4)
		        write(6,2000) ln(n),no(n),ds3,an3,
     .				      ln(m),no(m),ds4,an4,ds0
		      endif
		      go to 50
		   endif
		   if (rc.le.0.d0) then
		      x3 =fln3
		      y3 =flt3
		      ds4=0.d0
	      	      an4 =0.d0
		   elseif (rd.le.0.d0) then
		      x3 =fln4
		      y3 =flt4
		      ds4=dt(m)
	      	      an4 =nr(m)
		   endif
		   ds02=dsqrt(distline2(y3,x3,y4,x4))*111.12d0
		endif
		if (ds01.lt.ds02) then
		   if (ds01.le.15.d0) then
		     write(6,2000) ln(n),no(n),ds1,an1,
     .				   ln(m),no(m),ds2,an2,ds01
		   endif
		else
		   if (ds02.le.15.d0) then
		     write(6,2000) ln(n),no(n),ds3,an3,
     .				   ln(m),no(m),ds4,an4,ds02
		   endif
		endif
c	      endif
	   endif
   50	      continue
	   end do
   60	      continue
	end do
c
   90   stop
	end
c
c
c
	function ann1(n,ds1)
	parameter(idm=40000000,ndm=500000)
        implicit real*8(a-h,o-z)
	integer*4 nr1(ndm),nr(ndm)
	real*8 ds(idm)
	common nr1,nr,ds
	do nn=nr1(n)+1,nr1(n)+nr(n)
	   dds=ds(nn)-ds1
	   if (dds.gt.0.d0) then
	      ann1=dble(nn-nr1(n))-dds/(ds(nn)-ds(nn-1))
	      go to 90
	   endif
	end do
	ann1=dble(nr(n))
   90   return
	end   
c
c
c
	subroutine ann2(n,ds1,m,ds2,t,u)
	parameter(idm=40000000,ndm=500000)
	implicit real*8(a-h,o-z)
	integer*4 nr1(ndm),nr(ndm)
	real*8 aln(idm),alt(idm),ds(idm)
	common nr1,nr,ds,aln,alt
        do nn=nr1(n)+1,nr1(n)+nr(n)
           dds=ds(nn)-ds1
           if (dds.gt.0.d0) then
              go to 20
           endif
        end do
	nn =nr1(n)+nr(n)
   20   do mm=nr1(m)+1,nr1(m)+nr(m)
           dds=ds(mm)-ds2
           if (dds.gt.0.d0) then
              go to 30
           endif
        end do
	mm =nr1(m)+nr(m)
   30	no  =0
   40   no  =no-1
        call xycross(aln(nn-2),alt(nn-2),aln(nn+2),alt(nn+2),
     .       aln(mm-2),alt(mm-2),aln(mm+2),alt(mm+2),t,u)
        if (no.lt.-30) then
           t =9999.d0
           u =9999.d0
        endif
        if (t.eq.9999.d0.and.u.eq.9999.d0) then
           return
        endif
        if (t.lt.-0.05d0) then
           nn =nn-2
           if (nn.lt.nr1(n)+2) nn =nr1(n)+2
           t =9999.d0
        elseif(t.gt.1.05d0) then
           nn =nn+2
           if (nn.gt.nr1(n)+nr(n)-2) nn=nr1(n)+nr(n)-2
           t =9999.d0
        else
           nn=nn+int(t*4.d0)-1
           nno = 0
        endif
        if (u.lt.-0.05d0) then
           mm =mm-2
           if (mm.lt.nr1(m)+2) mm =nr1(m)+2
           go to 40
        elseif(t.gt.1.05d0) then
           mm =mm+2
           if (nn.gt.nr1(m)+nr(m)-2) mm=nr1(m)+nr(m)-2
           go to 40
        else
           mm=mm+int(u*4.d0)-1
           if (t.eq.9999.d0) go to 40
        endif
        no =0
   50	call xycross(aln(nn-1),alt(nn-1),aln(nn),alt(nn),
     .       aln(mm-1),alt(mm-1),aln(mm),alt(mm),t,u)
	if (t.eq.9999.d0.and.u.eq.9999.d0) then
	   return
	endif
     	nno =1
	if (t.lt.-0.05d0) then
	   nn =nn+int(t)-1
	   if (nn.lt.nr1(n)+1) nn =nr1(n)+1
	elseif(t.gt.1.05d0) then
	   nn =nn+int(t)
	   if (nn.gt.nr1(n)+nr(n)) nn=nr1(n)+nr(n)
	else
	   nno = 0
	endif
	if (u.lt.-0.05d0) then
	   mm =mm+int(u)-1
	   if (mm.lt.nr1(m)+1) mm =nr1(m)+1
	elseif(u.gt.1.05d0) then
	   mm =mm+int(u)
	   if (mm.gt.nr1(m)+nr(m)) mm=nr1(m)+nr(m)
	else
	   if (nno.eq.0) go to 70
	endif
	no =no+1
	if (no.lt.10) go to 50
          t =9999.d0
          u =9999.d0
        return
c
	if (nn-1.eq.nr1(n).and.t.le.0.d0) then
	  u =9999.d0
	  t =0.d0
	elseif (nn.eq.nr1(n)+nr(n).and.t.ge.1.d0) then
	  u =9999.d0
	  t =1.d0
	elseif (mm-1.eq.nr1(m).and.u.le.0.d0) then
	  t =9999.d0
	  u =0.d0
	elseif (mm.eq.nr1(m)+nr(m).and.u.ge.1.d0) then
	  t =9999.d0
	  u =1.d0
	endif
	return
   70	t =dble(nn-1-nr1(n))+t
	u =dble(mm-1-nr1(m))+u
  	return
	end
c--------------------------
c       function to calculate (dln,dlt) from two (lat, long) pairs
c       cos(lat) included in dln
c--------------------------
      function distline2(flt1,fln1,flt2,fln2)
        implicit real*8(a-h,o-z)
        data  fact/1.745329251994d-2/
c
        clt =dcos((flt2+flt1)*fact*.5d0)
        dlt =flt2-flt1
        dln =(fln2-fln1)*clt
	distline2=dlt*dlt+dln*dln
        return
        end
c--------------------------
c       function to calculate distance in km from point (x,y) to line (x1,y1) - (x2, y2)
c--------------------------
      subroutine distpline(flt1,fln1,flt2,fln2,flt,fln,ds,ra,rb)
        implicit real*8(a-h,o-z)
        data  fact2/55.56d0/
c
        r2 = distline2(flt1,fln1,flt2,fln2)
        p2 = distline2(flt1,fln1,flt,fln)
        q2 = distline2(flt2,fln2,flt,fln)
	r1  =dsqrt(r2)
        ra  =(r2+p2-q2)/r1*.5d0
	rb  =r1-ra
        pqr =(p2+q2-r2)**2
        ds  =dsqrt(4.d0*p2*q2-pqr)/r1*fact2
        return
        end
c-------------------------------------------------------------------
C     XYCROSS
c        subroutine to find cross point of two lines
c          input:  lat & long pairs of start & end points of the two lines
c          output: parts in the distances of two lines
c
c-------------------------------------------------------------------
        subroutine xycross(x1,y1,x2,y2,xa,ya,xb,yb,t,u)
        implicit real*8(a-h,o-z)
c
        x12 = x2-x1
        y12 = y2-y1
        xab = xb-xa
        yab = yb-ya
        x1a = xa-x1
        y1a = ya-y1
        det = x12*yab-y12*xab
	r1a = x12*x12+y12*y12+xab*xab+yab*yab
	det0= dabs(det)/r1a
        if (det0.lt.0.0001d0) then
          t =9999.d0
          u =9999.d0
        else
          t =(x1a*yab-y1a*xab)/det
          u =(x1a*y12-y1a*x12)/det
        endif
        return
        end

