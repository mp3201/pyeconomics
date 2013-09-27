!	----------------------------------------------------------------------
!	File name: SimulateData.f90
!
!	generate artificial data through simulating individuals' decision rules. These data
!	will be used in RegressLOM().
!	----------------------------------------------------------------------


subroutine SimulateData()

	use Globals
	use LinInterpModule
	use PolyInterpModule
	use Numerical_Libraries
	
	implicit none

	integer, parameter:: xseed = 2
	real(8), parameter:: tiny = 1.0D-20
	integer Z1

	real(8), dimension(:,:,:,:), allocatable:: ASkz
	real(8), dimension(:,:), allocatable:: CrA, CrPg, CrPb
	integer, dimension(:,:), allocatable:: CrBta, CrEps

   
	!	initialize time series data

	Kdata = 0.0D0
	Ldata = 0.0D0


	!	set the seed number for random number generator

	call rnset(xseed)


	!	allocate space for cross section data generation

	allocate(CrA(Nindiv,2), CrEps(Nindiv,2), CrPg(Nindiv,2), CrPb(Nindiv,2), CrBta(Nindiv,2),		&
			 ASkz(na,nP,nP,nbta))
    
	! Initial state assumed to be good. Also change this in generateseries if the initial state is a bad state
	
	Zdata(1) = 1
	
	!   Read the initial distribution from the file 
	
	open(1, file='Input\PanelA112B.txt', status = 'old')
    do indiv = 1, Nindiv
     read(1, *) CrA(indiv,1)
      CrA(indiv,2) = 0.0D0
    end do


    open(1, file='Input\PanelEps112B.txt', status = 'old')
    do indiv = 1, Nindiv
      read(1, *) CrEps(indiv,1)
      CrEps(indiv,2) = 0.0D0
    end do
 
    open(1, file='Input\PanelBta112B.txt', status = 'old')
    do indiv = 1, Nindiv
      read(1, *) CrBta(indiv,1)
      CrBta(indiv,2) = 0.0D0
    end do

	


    
	CrPg = 0.0
	CrPb = 0.0

    do indiv = 1, Nindiv
     
     if (CrEps(indiv,1) == 2 .and. Zdata(1) == 2) then 
	     CrPg(indiv,1) = 1.0
		 CrPb(indiv,1) = 0.0
	 end if
	 
	 if (CrEps(indiv,1) == 2 .and. Zdata(1) == 1) then 
	     CrPg(indiv,1) = 0.0
		 CrPb(indiv,1) = 1.0
     end if
   
    end do

	!	initial aggregate capital

	Kdata(1) = real(sum(CrA(:,1))/Nindiv)



	!	start generating artificial time series data

	do time = 1, N1

		
		do indiv = 1, Nindiv
        
		  CrA(indiv,2) = lininterp3(CrA(indiv,1), CrPg(indiv,1), CrPb(indiv,1), agrid, PGgrid, PBgrid, AS2(time,:,:,:,CrBta(indiv,1)))
		  CrA(indiv,2) = min(max(CrA(indiv,2), agrid(1)), agrid(na))
		 
		end do
     
		!	next period variables

		Kdata(time+1) = min(max(sum(CrA(:,2))/Nindiv, kgrid(1)), kgrid(nk))
      
		
		call NextBeta(CrBta)
		call NextP2(CrPg,CrPb)
       if (time==1) then
	   	open(1, file='Output\CrA.txt', status='unknown')
	    open(2, file='Output\CrPg.txt', status='unknown')
	    open(3, file='Output\CrPb.txt', status='unknown')
	

		 write(1, '(F15.6)') CrA(:,2)
		 write(2, '(F15.6)') CrPg(:,2)
		 write(3, '(F15.6)') CrPb(:,2)

	   
	   end if 
	
		!	lag cross section data one period

		CrA(:,1) = CrA(:,2)
        CrBta(:,1) = CrBta(:,2)
		CrPg(:,1) = CrPg(:,2)
		CrPb(:,1) = CrPb(:,2)

		!	show how simulation is going on

		if (mod(time, 100) == 0) then
			write(*,'(A,I6)')   "time = ", time	
			write(*,'(A,F12.6)') "K = ", Kdata(time)
			write(*,'(A,F12.6)') "Kp = ", Kdata(time+1)
			write(*,'(/)')
		end if
 
	end do

	!	start generating artificial time series data

	do time = N1+1, Nperiod


	! interpolate value function and asset decision rule at (Kapital, z)
       

		do ia = 1, na
        do iPg = 1, nP
		do iPb = 1, nP
        do ibta = 1, nbta
		
			ASkz(ia,iPg,iPb,ibta) = polyinterp1(Kdata(time), kgrid, AS(ia,iPg,iPb,ibta,:))
		
		end do	
		end do
        end do
		end do

		!	cross-section data for asset and hours given (Kapital)

		do indiv = 1, Nindiv

		 CrA(indiv,2) = lininterp3(CrA(indiv,1), CrPg(indiv,1), CrPb(indiv,1), agrid, PGgrid, PBgrid, ASkz(:,:,:,CrBta(indiv,1)))
		 CrA(indiv,2) = min(max(CrA(indiv,2), agrid(1)), agrid(na))
        

		end do
		
		Kdata(time+1) = min(max(sum(CrA(:,2))/Nindiv, kgrid(1)), kgrid(nk))
        
        
		call NextBeta(CrBta)
		call NextP(CrPg,CrPb)

		
		!	lag cross section data one period

		CrA(:,1) = CrA(:,2)
        CrBta(:,1) = CrBta(:,2)
		CrPg(:,1) = CrPg(:,2)
		CrPb(:,1) = CrPb(:,2)
		
		
		!	show how simulation is going on

		if (mod(time, 100) == 0) then
			write(*,'(A,I6)')   "time = ", time	
			write(*,'(A,F12.6)') "K = ", Kdata(time)
			write(*,'(A,F12.6)') "Kp = ", Kdata(time+1)
			write(*,'(/)')
		end if

   end do
   


	!	deallocate memory

	deallocate(CrA, CrEps, CrPg, CrPb, ASkz, CrBta)


	!	save time sries data

	open(1, file='Output\Kdata.txt', status='unknown')
	close(1, status='delete')

	open(1, file='Output\Kdata.txt', status='unknown')
    write(1, '(f12.6)') Kdata



end subroutine
