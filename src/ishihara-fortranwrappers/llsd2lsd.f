c
	parameter(ndm=1000000)
	implicit real*8(a-h,o-z)
	integer*4 iy(ndm)
	real*8 dy(ndm),an(ndm),at(ndm),af(ndm),ds(ndm)
	ddm =45.d0/86400.d0
	ln0 =0
	i   =0
   10 read(5,*,end=90) ln,no,iy1,dy0,an0,at0,af0,ds0
      if (ln.ne.ln0.or.no.ne.no0) then
	   ie =i
	if (ie.gt.0) then
	   nsp=int(ds(ie)/110.d0)+1
	   dsp=ds(ie)/dble(nsp)
c	write(6,*) ie,nsp,dsp
     	   nn=nn+1
	   ds1=0.d0
	   do i=1,ie
		 ds2 =ds(i)-ds1
     	      if (ds2.gt.dsp) then
		 ds1 =ds(i)
		 ds2 =ds(i)-ds1
	         nn =nn+1
	      endif
	      write(6,2000) ln0,nn,iy(i),dy(i),an(i),at(i),af(i),ds2
	   end do
	endif
	   i  =0
	   no0=no
   	   if (ln.ne.ln0) then
	      nn =0
	      ln0=ln
	   endif
      endif
      if (no.eq.0) then
           write(6,2000) ln,no,iy1,dy0,an0,at0,af0,ds0
	   go to 10
      endif
	i =i+1
	iy(i)=iy1
	dy(i)=dy0
	an(i)=an0
	at(i)=at0
	af(i)=af0
	ds(i)=ds0
	go to 10
c
   90 stop
 2000 format(i5,i6,i5,f12.7,2f11.5,f10.2,f10.2)
      end
