c --------------------------
c    LFLC
c       minimize x-over difference by distance weight
c       apply weighted sum if d < d1
c       weight: ((d/d3)**2+1)**2 for data with sampling rate > 1.5 min
c               ((d/d3)**2+1)*((d/d2)**2+1) for data with sampling rate < 1.5 min
c	   d1 = 8.0 km
c	   d2 = 0.5 km
c	   d3 = 2.5 km
c-------input and output files (weight files are prepared before this program)
c	   fl1: source data
c	   fl2: line   data
c	   fl3: weight data
c	   fl4: output
c-------dimension parameters (actual numbers):
c	   idm (ie): source records
c	   ldm (le): cruises   	
c	   ndm (ne): lines
c	   kdm (ke): weight data
c -------------------------
	parameter(idm=20000000,ldm=10000,kdm=10000000,ndm=450000)
	implicit real*4(a-h,o-z)
	integer*4 lnr(ldm),lnn(ldm),nok(ldm),mx(ldm),nl(ldm),ln2(kdm)
        integer*4 ln(ndm),no(ndm),n1(ndm),n2(ndm),iy(ldm),nn1(kdm)
	integer*4 it(6)
	real*4 a0(idm),a1(idm)
	real*4 cr(idm),wt(idm),ws(kdm),cs(kdm)
        real*4 sc(ldm),sc0(ldm),sx(ldm),wl(ldm)
        real*4 gs(1001),dg(1001)
	real*8 at(idm),an(idm),dy(idm),dy1(kdm)
        real*8 dn1(kdm),dn2(kdm),ds(idm),dd,dt1,dt2,dnn1,dnn2,dyy1

	character*50 fl1,fl2,fl3,fl4
c
 2000 format(2i5,2i2.2,1x,3i2.2,2f11.5,2f10.2,2f14.4)
 3000 format(/' Iteration',i4,' SD =',f6.2,'  NO of cruises >',f4.0,
     .         'nT :',i4,'; >10 nT :',i4,'     Top 24 are :')
 4000   format(6(i7,f8.2))
 5000   format(a50)
 6000 format('-- Iteration calculation')

c
	   gs(1)   =1.
	   dg(1001)=0.
	   do i=1,1000
	      x =float(i)*0.001d0
	      gs(i+1) =exp(-4.5*x*x)
	      dg(i)   =gs(i+1)-gs(i)
	   end do

	write(6,3001)
 3001 format('-- Parameter input')
c
c full width of Gaussian filter in hours and number of repetitions : dt0
        read(5,*) dt0, m2
c Total numbers of repititions including filter with of the double of dt0
        read(5,*) m1
c
        dt5 =dt0*.5/24.
	dt1 =dt5*2.
	dt2 =dt5

c
c limits of weight sums f1 & f2
        read(5,*) f1,f2
c
 3002 format(9x,'Full width=',f6.2,' hrs',8x,i3,' repetitions')
 3003 format(9x,'Total including double width',i4,' repetitions')
 3004 format(9x,'Limits of weight sums f1 & f2 :',2f6.3,/)
	write(6,3002) dt0,m2
	write(6,3003) m1
	write(6,3004) f1,f2
c
c limit of maximum correction (nT)
        read(5,*) sclmt
c
c input file
        read(5,5000) fl1
c
c stat file
        read(5,5000) fl2
c
c weight file
        read(5,5000) fl3
c
c output file
        read(5,5000) fl4
c
	write(6,3005)
 3005 format('-- Data input')
c
c---- lsd file
        open(10,file=fl1)
        i =1
	ln0 =0
	l =0
   10   read(10,*,end=12) ln1,no0,iy1,dy(i),an(i),at(i),a0(i),ds(i)
	if (an(i).gt.180.d0) an(i)=an(i)-360.d0
	if (ln1.eq.176) then
	   a0(i) =a0(i)-800.
	elseif (ln1.eq.1737) then
	   a0(i) =a0(i)+1000.
	elseif (ln1.eq.2557.or.ln1.eq.2560.or.ln1.eq.2561) then
	   a0(i) =a0(i)+200.
	endif
	a1(i)=a0(i)
	if (ln1.ne.ln0) then
	   do l=ln0+1,ln1
	      lnr(l)=i
	   end do
c	   l     =l+1
	   iy(ln1) =iy1
	   ln0   =ln1
	   lnn(ln1)=ln0
	elseif (iy1.ne.iy(ln0)) then
	   dy(i)=dy(i)+365.d0
	   if (mod(iy(ln0),4).eq.0) dy(i)=dy(i)+1.d0
	endif
        i =i+1
        go to 10
c
   12   ie=i-1
	le=ln0
	lnr(le+1)=i
        close(10)

c---- stat file
        open(20,file=fl2)
        read(20,'(60x)')
        read(20,'(60x)')
        i =1
   13   read(20,*,end=14) ln(i),no(i),n1(i),n2(i),iy1,dy01,dy02,
     .         ddy,aln1,aln2,dln,alt1,alt2,dlt,dt,hd
        i =i+1
        go to 13

   14   ne =i-1
        close(20)

c---- lwt file
	do l=1,5000
	   nok(l) =0
	end do
        open(30,file=fl3)
	ln0=0
   20	read(30,*,end=30) k,lnn1,no1,dnn1,dyy1,lnn2,no2,dnn2,dy2,wss
	dn1(k)=dnn1
	dn2(k)=dnn2
	dy1(k)=dyy1
	nn1(k)=lnn1
	ln2(k)=lnn2
	ws(k) =wss
	if (lnn1.ne.ln0) then
	   do l=ln0+1,lnn1
	      nok(l)=k
	   end do
	   ln0   =lnn1
	endif
	go to 20

   30	close(30)
    	ke=k
        nok(ln1+1)=k+1
	write(6,3006) ie,le,ne,ke
 3006 format(9x,'Number of records=',i8,',  cruises=',
     .       i5,',  lines=',i6,' and  weight data=',i8,/)
c
c----- calculation of wt
c

      do l=1,le
        do i=lnr(l),lnr(l+1)-1
          sw   =0.
	  if (nok(l+1).gt.nok(l)) then
          do ii=nok(l),nok(l+1)-1
            dt =dy1(ii)-dy(i)
            if(dt.gt.dt5) go to 23
            if(dt.ge.-dt5) then
              gs0 =gauss(abs(dt/dt5),gs,dg)
              sw  =sw+gs0*ws(ii)
	    endif
	  end do
	  endif
   23     wt(i) =sw
	end do
      end do
c
	write(6,6000)
c
c----- iteration
c

      do m=1,m1
	lx =0
	llx=0
	l0 =2000
	if (m.le.m2) then
	   dt5 =dt2
	else
	   dt5 =dt1
	endif
c
c----- calculation of cs
c
	ss =0.d0
	sn =0.d0
      do l=1,le
	  wl(l)=0.
	  ssl  =0.
	  if (nok(l+1).gt.nok(l)) then
        do ii=nok(l),nok(l+1)-1
	      no1=int(dn1(ii))
	      no2=int(dn2(ii))
	if (no1.lt.1.or.no1.gt.ie) then
	   write(6,*) 1,no1,ii
	   stop
	endif
	if (no2.lt.1.or.no2.gt.ie) then
	   write(6,*) 2,no2,ii
	   stop
	endif
	      dd =dn1(ii)-dble(no1)
	      a10=a1(no1)+dd*(a1(no1+1)-a1(no1))
	      dd =dn2(ii)-dble(no2)
	      a20=a1(no2)+dd*(a1(no2+1)-a1(no2))
              cs(ii)=ws(ii)*(a20-a10)
	      if (ws(ii).eq.1.) then
		wl(l)=wl(l)+(a20-a10)**2
		ss =ss+(a20-a10)**2
		sn =sn+1.
		ssl=ssl+1.
	      endif
	end do
	  endif
	  if (ssl.gt.0.) then
	     wl(l)=wl(l)/ssl
c	     if (m.eq.m1) write(6,*) l,wl(l)
	  endif
      end do
	sgm =sqrt(ss/sn)
      do l=1,le
	sc(l) =0.d0
	sx(l) =0.d0
        do i=lnr(l),lnr(l+1)-1
          sw =0.
          sy =0.
          scr=0.
	  if (nok(l+1).gt.nok(l)) then
          do ii=nok(l),nok(l+1)-1
            dt =dy1(ii)-dy(i)
            if(dt.gt.dt5) go to 47
            if(dt.ge.-dt5) then
              gs0=gauss(abs(dt/dt5),gs,dg)
              sw =sw+gs0*ws(ii)
	      lnn1=nn1(ii)
	      lnn2=ln2(ii)
        if (lnn2.lt.1.or.lnn2.gt.le) then
	   write(6,*) ii,lnn1,lnn2
	   stop
	endif
	      wll=wl(l)/(wl(l)+wl(lnn2))
              sy =sy+gs0*cs(ii)*wll
	    endif
   45       continue
	  end do
	  endif
   47     if (sw.gt.f1) then
             cr(i) =sy/sw
c---------- limit of sw = f1
          elseif (sw.gt.f2) then
             cr(i) =sy/f1
c---------- limit of sw = f2
          else
             cr(i) =sy*sw/f1/f2
          endif
         abcr  =abs(cr(i))
         if (abcr.gt.abs(sx(l))) sx(l) =cr(i)
	  scr=scr+cr(i)*cr(i)
	end do
	as =lnr(l+1)-lnr(l)
	if (as.eq.0.) then
	  sc(l)=0.
	else
	  sc(l)=sqrt(scr/as)
	endif
c
c----- ordering of cruise maximum values of cr
c
	  if (abs(sx(l)).gt.sclmt) llx =llx+1
	  lx    =lx+1
	  mx(lx)=l
	  if (lx.gt.1) then
	     do ll=lx,2,-1
	        scj =abs(sx(mx(ll-1)))
	        if (abs(sx(l)).le.scj) go to 50
	        mx(ll)   =mx(ll-1)
	        mx(ll-1) =l
	     end do
	  endif
   50     continue
      end do
c
c	i =lnr(l0)
c	write(6,*) l0,lnr(l0),lnr(l0+1)
c      do ii=nok(l0),nok(l0+1)-1
c	dt0 =9999.d0
c	if (ws(ii).eq.1) then
c   52      dt =dabs(dy1(ii)-dy(i))
c	   if (dt.lt.dt0) then
c	      dt0 =dt
c	      i =i+1
c	      if (i.ge.lnr(l0+1)) go to 55
c	      go to 52
c	   else
c      write(6,3050) m,dy1(ii),dy(i-1),df(ii),cs(ii),cr(i),wt(i)
c	   endif
c	endif
c      end do
c 3050 format(i3,2f10.4,3f7.2,f8.4)
c
   55	do l=0,le
	  if (abs(sx(mx(l+1))).lt.10.) go to 61
	end do
   61   ll10=l
	if (m.gt.1.and.abs(1.5*sc0(mx(1))).lt.abs(sc(mx(1)))) go to 90
c
c----- listing of 24 maximum values of cr
c
        write(6,3000) m,sgm,sclmt,llx,ll10
        write(6,4000) (lnn(mx(j)),sx(mx(j)),j=1,24)
c        write(6,4000) (lnn(mx(j)),sc(mx(j)),sx(mx(j)),j=1,24)
	if (llx.eq.0) go to 90
c
c
c----- addition of half of cr to a1
	do l=1,le
	   asx =abs(sx(l))
	   if (m.eq.1.or.asx.lt.abs(sc0(l))) then
	     do i=lnr(l),lnr(l+1)-1
               a1(i) =a1(i)+cr(i)
	     end do
 	     sc0(l) =sx(l)
	   endif
	end do
      end do
c
c----- end of iteration
c
c----- output of the results
c
   90   open(40,file=fl4)
      do l=1,le
	do i=lnr(l),lnr(l+1)-1
	  call dy2mdhms(iy(l),dy(i),it)
      	  write(40,2000) l,it,an(i),at(i),a0(i),a1(i)
     .                  ,cr(i),wt(i)
	end do
      end do
 	close(40)
c
	stop
	end
c
c-----------------------------------------------------------------
       function wght(dd0,nf0,nf)
c       function wght(dd0,nf0,nf,ds,t0)
        implicit real*8(a-h,o-z)
	real*8 dd0,r2d,rd2
        data d1,d2,d3/225.,.25,6.25/
        r2d =111.12d0
        rd2 =r2d*r2d
c
           wght =0.d0
c          dd   =dd0*rd2
	   dd  =dd0*dd0
           if (dd.gt.d1) then
              go to 50
           endif
c          w  =1.d0
              w0   =1./((dd/d3)+1.)
c           if (nf.eq.nf0) then
c              dt =abs(ds)
c              if(dt.lt.t0) then
c                go to 50
c              elseif(dt.lt.t0*2.d0) then
c                w0 =w0*(dt-t0)/t0
c              endif
c           endif
              if (nf0.gt.5000.and.nf.gt.5000) then
                 w2=1./((dd/d2)+1.)
                 w =w0*(d3/d2)**1.5*w2
              else
                 w =w0*w0
              endif
              if (w.gt.0.00001) wght =w
   50   return
        end
c------------------------------------------------------------------
        function gauss(x,gs,dg)
        real*4 x,gauss,gs(1001),dg(1001)
	   y =abs(x)*1000.
	   i =int(y)
	   dy=y-float(i)
	   gauss =gs(i+1)+dg(i+1)*dy
        return
        end
C-------------------------------------------------------------------
C   Function for calculating time in year   from YYYY,MM,DD,HH,MM,SS
c     Julian day - 1 used
C-------------------------------------------------------------------
      FUNCTION dttm2dy(iy0,idt,itm)
      implicit real*8(a-h,o-z)
      integer*4 it(6)
c
      it(1) =idt/10000
      imd   =idt-it(1)*10000
      it(2) =imd/100
      it(3) =imd-it(2)*100
      it(4) =itm/10000
      ims   =itm-it(4)*10000
      it(5) =ims/100
      it(6) =ims-it(5)*100
c
      jd = jlday(it(1),it(2),it(3))
      if (it(1).gt.iy0)then
	if(mod(iy0,4).eq.0) then
	 jd =jd+366
        else
	 jd =jd+365
	endif
      endif
      dttm2dy = dble(jd-1) + dble(it(4)*3600+it(5)*60+it(6))/86400.d0
      RETURN
      END
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
C-------------------------------------------------------------------
C   subroutine to calculate from time in year to month, day, hour, min, sec
c     Julian day is obtained by adding 1
C-------------------------------------------------------------------
      Subroutine dy2mdhms(iy0,dy,it)
      implicit real*8(a-h,o-z)
      integer*4 it(6)
c
      iy   =iy0
      is   =nint(dy*86400.d0)
      jd    =is/86400
      id    =is - jd*86400
	if (mod(it(1),4).eq.0) then
	   id0 =366
	else
	   id0 =365
	endif
	if (jd.gt.iy0) then
	    jd =jd-id0
	    iy =iy+1
	endif
      it(1) =iy
      it(4) =id/3600
      ims   =id - it(4)*3600
      it(5) =ims/60
      it(6) =ims - it(5)*60
      md    =mnday(it(1),jd+1)
      it(2) =md/100
      it(3) =md-it(2)*100
      RETURN
      END
c-----------------------------------------------------------------------
c   Conversion from Julian day to month+day
c-----------------------------------------------------------------------
	function mnday(iyr,jday)
	implicit none
	integer*4 kday(12),mday,lday,n,iyr,jday,mnday
	data kday/0,31,59,90,120,151,181,212,243,273,304,334/
	do 10 n = 0,11
	   mday =kday(n+1)
	   if (mod(iyr,4).eq.0.and.n.ge.2) mday = mday+1
	   if (jday.le.mday) goto 90
	   lday = mday
   10	continue
	n = 12
   90   mnday = jday-lday+n*100
	return
	end
