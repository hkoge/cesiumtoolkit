c --------------------------
c    LWT
c       minimize x-over difference by distance weight
c       apply weighted sum if d < d1
c       weight: ((d/d3)**2+1)**2 for data with sampling rate > 1.5 min
c               ((d/d3)**2+1)*((d/d2)**2+1) for data with sampling rate < 1.5 min
c-------input and output files (weight distance files are prepared before this program)
c	   fl1: source   data
c	   fl2: line     data
c	   fl3: distance data
c	   fl4: weight   data
c-------dimension parameters (actual numbers):
c	   idm (ie): source records
c	   ldm (le): cruises   	
c	   ndm (ne): lines
c	   kdm (ke): weight data
c -------------------------
	parameter(idm=40000000,ldm=5000,kdm=10000000,ndm=450000)
	implicit real*8(a-h,o-z)
	real*8 dy(idm)
c	real*8 at(idm),an(idm),dy(idm),dy1(kdm)
c	real*8 a0(idm),a1(idm),cr(idm),wt(idm)
c	real*4 cr(idm),wt(idm),ws(kdm),cs(kdm)
c       real*8 sc(ldm),sc0(ldm),sx(ldm)
c        real*8 dn1(kdm),dn2(kdm),ds(idm),dd,dt1,dt2

	integer*4 lnr(ldm),lnn(ldm),nok(ldm),nl(ldm)
        integer*4 ln(ndm),no(ndm),n1(ndm),n2(ndm),iy(ldm)
	integer*4 it(6)
	character*50 fl1,fl2,fl3,fl4
c
 5000   format(a50)
c
c----- sampling interval of y0,c0: 30 min  (in year)
c

        read(5,5000) fl1
        read(5,5000) fl2
        read(5,5000) fl3
        read(5,5000) fl4
c
	write(6,3001)
 3001 format('-- step 1 -- data input')
c
c---- llsd file
        open(10,file=fl1)
        i =1
	ln0 =0
	l =0
   10   read(10,*,end=12) ln1,no0,iy1,dy(i),an,at,a0,ds
c	if (an(i).gt.180.d0) an(i)=an(i)-360.d0
c	a1(i)=a0(i)
	if (ln1.ne.ln0) then
	   ln0   =ln1
	   l     =l+1
	   iy(l) =iy1
	   lnr(l)=i
	   lnn(l)=ln0
	elseif (iy1.ne.iy(l)) then
	   dy(i)=dy(i)+365.d0
	   if (mod(iy(l),4).eq.0) dy(i)=dy(i)+1.d0
	endif
        i =i+1
        go to 10
c
   12   ie=i-1
	le=l
	lnr(le+1)=i
        close(10)

c---- stat file
        open(20,file=fl2)
        read(20,'(60x)')
        read(20,'(60x)')
        i =1
   13   read(20,*,end=14) ln(i),no(i),n1(i),n2(i),iy1,dy01,dy02,
     .         ddy,aln1,aln2,dln,alt1,alt2,dlt,dt,hd
c	write(6,*) ln(i),no(i),n1(i),dy1(i)
        i =i+1
        go to 13

   14   ne =i-1
	write(6,4001) ie,le,ne
 4001 format(9x,'Number of records=',i8,'  cruises=',i4,'  lines=',i6)
        close(20)

c---- xfind2 file
        open(30,file=fl3)
        open(40,file=fl4)
        i =1
	k =1
	l =0
	ln0=0
   15   read(30,*,end=30) ln1,no1,dt1,dm1,ln2,no2,dt2,dm2,ds0
	if (ln1.ne.ln0) then
   25	   l  =l+1
	   nok(l)=k
	   if (ln1.gt.lnn(l)) go to 25
	   ln0=ln1
	endif
   16	if (ln1.gt.ln(i).or.no1.gt.no(i)) then
	   i =i+1
	   go to 16
	endif
	dn1 =dble(n1(i))+dm1
	nd1 =int(dn1)
	dd  =dn1-dble(nd1)
	dy1 =dy(nd1)+dd*(dy(nd1+1)-dy(nd1))
c   	ii =n1(i)
c   17	if (ds(ii+1).lt.dt1) then
c	   ii=ii+1
c	   go to 17
c	endif
c	dd0 =ds(ii+1)-ds(ii)
c	if (dd0.le.0.01d0) then
c	   dd =0.d0
c	else
c	   dd =(dt1-ds(ii))/dd0
c	endif
c	dn1(k) =dble(ii)+dd
c	dy1(k) =dy(ii)+dd*(dy(ii+1)-dy(ii))
c

	j =1
	do j=1,ne
	   if (ln(j).eq.ln2.and.no(j).eq.no2) go to 18
	end do
c   18	jj =n1(j)
   18	dn2 =dble(n1(j))+dm2
	nd2 =int(dn2)
	dd  =dn2-dble(nd2)
	dy2 =dy(nd2)+dd*(dy(nd2+1)-dy(nd2))
c   19	if (ds(jj+1).lt.dt2) then
c	   jj=jj+1
c	   go to 19
c	endif
c	dd0 =ds(jj+1)-ds(jj)
c	if (dd0.le.0.01d0) then
c	   dd =0.d0
c	else
c	   dd =(dt2-ds(jj))/dd0
c	endif
c	dn2(k) =dble(jj)+dd
c	dy2 =dy(jj)+dd*(dy(jj+1)-dy(jj))
c	ss0 =ds0/6.25
c	ws  =1./(ss0*ss0+1.)**2
c----------------change ss0 -------------------
	ss0 =ds0
	ss1 =ds0/0.25
	ws  =1./((ss0*ss0+1.)*(ss1*ss1+1.))**2
c	ws  =wght(ds0,ln1,ln2)
       write(40,4000) k,ln1,no1,dn1,dy1,ln2,no2,dn2,dy2,ws
	k =k+1
	go to 15
 4000  format(i8,2(2i5,f12.2,f10.5),e12.5)

   30	close(30)
c	stop
    	ke=k-1
        nok(l+1)=k
 4002 format(9x,'Number of weight data=',i10)
	write(6,4002) ke
	stop
c
c-----------------------------------------------------------------
cc       function wght(dd0,nf0,nf)
c       function wght(dd0,nf0,nf,ds,t0)
cc        implicit real*8(a-h,o-z)
cc	real*8 dd0,r2d,rd2
cc        data d1,d2,d3/225.,.25,6.25/
cc        r2d =111.12d0
cc        rd2 =r2d*r2d
c
cc           wght =0.d0
c          dd   =dd0*rd2
cc	   dd  =dd0*dd0
cc           if (dd.gt.d1) then
cc              go to 50
cc           endif
c          w  =1.d0
cc              w0   =1./((dd/d3)+1.)
c           if (nf.eq.nf0) then
c              dt =abs(ds)
c              if(dt.lt.t0) then
c                go to 50
c              elseif(dt.lt.t0*2.d0) then
c                w0 =w0*(dt-t0)/t0
c              endif
c           endif
cc              if (nf0.gt.5000.and.nf.gt.5000) then
cc                 w2=1./((dd/d2)+1.)
cc                 w =w0*(d3/d2)**1.5*w2
cc              else
cc                 w =w0*w0
cc              endif
cc              if (w.gt.0.00001) wght =w
cc   50   return
        end
