c --------------------------
c    LLFINDDBL
c       
c	doubling the llfind data
c -------------------------
	implicit real*8(a-h,o-z)
c
 2000   format(2(i5,i5,2f12.4),f10.2)
 2010   format(2(i5,i5,2f12.4),f10.2,i3)
c
   30  	read(5,2000,end=90) ln1,no1,ds1,an1,ln2,no2,ds2,an2,dt
	write(6,2000) ln1,no1,ds1,an1,ln2,no2,ds2,an2,dt
	write(6,2000) ln2,no2,ds2,an2,ln1,no1,ds1,an1,dt
	go to 30
c
   90	stop
	end
