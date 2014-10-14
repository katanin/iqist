!!!-------------------------------------------------------------------------
!!! project : jasmine
!!! program : atomic_config
!!! source  : atomic_config.f90
!!! type    : subroutines
!!! author  : yilin wang (email: qhwyl2006@126.com)
!!! history : 07/09/2014 by yilin wang
!!!           08/22/2014 by yilin wang
!!! purpose : set control parameters 
!!! status  : unstable
!!! comment :
!!!-------------------------------------------------------------------------

!!>>> atomic_config: read config parameters from file 'atom.config.in'
  subroutine atomic_config()
     use constants, only : dp, mytmp
     use control

     use parser, only : p_create, p_destroy, p_parse, p_get
  
     implicit none
  
! local variables
! file status
     logical :: exists
     
!----------------------------------------------------------------
     itask  = 1           ! type of task
     ictqmc = 1           ! type of CTQMC algorithm
     icf    = 0           ! type of crystal field
     isoc   = 0           ! type of spin-orbital coupling (SOC)
     icu    = 1           ! type of Coulomb interaction
     
!---------------------------------------------------------------- 
     nband = 1            ! number of bands
     nspin = 2            ! number of spins
     norbs = nband*nspin  ! number of orbits
     ncfgs = 2**norbs     ! number of many-body configurations

!----------------------------------------------------------------
     Uc = 2.00_dp         ! intraorbital Coulomb interaction
     Uv = 2.00_dp         ! interorbital Coulomb interaction
     Jz = 0.00_dp         ! Hund's exchange interaction
     Js = 0.00_dp         ! spin-flip interaction
     Jp = 0.00_dp         ! pair-hopping interaction
  
!----------------------------------------------------------------
     Ud = 2.00_dp         ! Ud
     JH = 0.00_dp         ! JH
     F0 = 0.00_dp         ! F0
     F2 = 0.00_dp         ! F2
     F4 = 0.00_dp         ! F4
     F6 = 0.00_dp         ! F6
  
!----------------------------------------------------------------
     lambda = 0.00_dp     ! spin-orbit coupling parameter
     mune   = 0.00_dp     ! chemical potential
  
!----------------------------------------------------------------
! file status
     exists = .false.
  
! inquire the input file status
     inquire( file="atom.config.in", exist=exists )
  
! read parameters from atom.config.in
     if ( exists .eqv. .true. ) then
!----------------------------------------------------------------
         call p_create()
         call p_parse('atom.config.in')
!----------------------------------------------------------------
         call p_get('nband', nband)
!----------------------------------------------------------------
         call p_get('itask',  itask)
         call p_get('ictqmc', ictqmc)
         call p_get('icf',    icf)
         call p_get('isoc',   isoc)
         call p_get('icu',    icu)
!----------------------------------------------------------------
         call p_get('Uc',     Uc) 
         call p_get('Uv',     Uv) 
         call p_get('Jz',     Jz) 
         call p_get('Js',     Js) 
         call p_get('Jp',     Jp) 
!----------------------------------------------------------------
         call p_get('Ud',     Ud) 
         call p_get('JH',     JH) 
!----------------------------------------------------------------
         call p_get('lambda', lambda)
         call p_get('mune',   mune)
!----------------------------------------------------------------
         call p_destroy()
!----------------------------------------------------------------
! calculate the norbs and ncfgs
         norbs = nband * nspin
         ncfgs = 2 ** norbs 

! calculate F0, F2, F4, F6 here
         F0 = Ud
         if (nband == 5) then
             F2 = JH * 14.0_dp / 1.625_dp 
             F4 = 0.625_dp * F2
         elseif(nband == 7) then
             F2 = JH * 6435.0_dp / (286.0_dp + (195.0_dp * 451.0_dp / 675.0_dp) &
                                            + (250.0_dp * 1001.0_dp / 2025.0_dp))
             F4 = 451.0_dp / 675.0_dp * F2
             F6 = 1001.0_dp / 2025.0_dp * F2
         endif
!----------------------------------------------------------------
     else
         call s_print_error('atomic_config', 'no file atom.config.in !')
     endif
  
     return
  end subroutine atomic_config
!!!-------------------------------------------------------------------------
!!! project : jasmine
!!! program : atomic_read_cf
!!!           atomic_read_eimp
!!!           atomic_read_umat
!!! source  : atomic_natural.f90
!!! type    : subroutines
!!! author  : yilin wang (email: qhwyl2006@126.com)
!!! history : 07/09/2014 by yilin wang
!!!           08/22/2014 by yilin wang
!!! purpose : read data from files
!!! status  : unstable
!!! comment :
!!!-------------------------------------------------------------------------

!!>>> atomic_read_cf: read crystal field from file 'atomic.cf.in'
  subroutine atomic_read_cf()
     use constants, only : mytmp, dp, zero
     use m_spmat, only : cfmat
  
     implicit none
  
! local variables
! file status
     logical :: exists

! iostat
     integer :: ierr

! dummy variables
     integer :: i, j
     real(dp) :: r1
  
! we read crystal field from file "atom.cf.in"
! inquire file
     inquire(file='atom.cf.in', exist=exists)
  
     if (exists .eqv. .true.) then
         open(mytmp, file='atom.cf.in')
         do while(.true.)
             read(mytmp, *, iostat=ierr) i, j, r1
             ! crystal field is actually real
             cfmat(i,j) = dcmplx(r1, zero)
             if (ierr /= 0) exit
         enddo
     else
         call s_print_error('atomic_read_cf', 'no file atomic.cf.in !')
     endif 
  
     return
  end subroutine atomic_read_cf

!!>>> atomic_read_eimp: read on-site impurity energy 
!!>>> from file 'atomic.eimp.in'
  subroutine atomic_read_eimp()
     use constants, only : mytmp, dp, zero
     use control, only : norbs

     use m_spmat, only : eimpmat
  
     implicit none
  
! local variables
! file status
     logical :: exists

! loop index
     integer :: i

! dummy variables
     integer :: i1, i2
     real(dp) :: r1
  
! we read eimp from file 'atomic.eimp.in'
     inquire(file='atom.eimp.in', exist=exists)
  
     if (exists .eqv. .true.) then
         open(mytmp, file='atom.eimp.in')
         do i=1, norbs
             read(mytmp, *) i1, i2, r1
             ! eimpmat is actually real in natural basis
             eimpmat(i,i) = dcmplx(r1, zero)
         enddo 
     else
         call s_print_error('atomic_read_eimp', 'no file atomic.eimp.in !')
     endif
  
     return
  end subroutine atomic_read_eimp
  
!!>>> atomic_read_umat: read the transformation matrix 
!!>>> tran_umat from file 'atomic.umat.in'
  subroutine atomic_read_umat()
     use constants, only : mytmp, dp, zero
     use control, only : norbs

     use m_spmat, only : tran_umat
  
     implicit none
  
! local variables
! file status
     logical :: exists

! loop index
     integer :: i, j

! dummy variables
     integer :: i1, i2
     real(dp) :: r1
  
! we read ran_umat from file 'atomic.umat.in'
     inquire(file='atom.umat.in', exist=exists)
  
     if (exists .eqv. .true.) then
         open(mytmp, file='atom.umat.in')
         do i=1, norbs
             do j=1, norbs
                 read(mytmp, *) i1, i2, r1
                 tran_umat(j,i) = dcmplx(r1, zero)
             enddo
         enddo
     else
         call s_print_error('atomic_read_umat', 'no file atomic.umat.in')
     endif
  
     return
  end subroutine atomic_read_umat
!!!-------------------------------------------------------------------------
!!! project : jasmine
!!! program : atomic_check_config
!!!           atomic_check_realmat
!!! source  : atomic_check.f90
!!! type    : subroutines
!!! author  : yilin wang (email: qhwyl2006@126.com)
!!! history : 07/09/2014 by yilin wang
!!!           08/22/2014 by yilin wang
!!! purpose : do some checks
!!! status  : unstable
!!! comment :
!!!-------------------------------------------------------------------------

!!>>> atomic_check_config: check the validity of input config parameters
  subroutine atomic_check_config()
     use constants, only : mystd, zero
     use control
  
! local variables
     logical :: lpass
  
     lpass = .true.
  
! check nband
     if (nband <= 0) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: number of bands must &
                                                    be larger than zero !'
         write(mystd, *)
         lpass = .false.
     endif
  
! check itask
     if (itask /= 1 .and. itask /= 2) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: itask must be 1 or 2 !'
         write(mystd, *)
         lpass = .false.
     endif
  
! check icf
     if (icf /= 0 .and. icf /=1 .and. icf /= 2) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: icf must be one of 0, 1, 2 !'
         write(mystd, *)
         lpass = .false.
     endif
  
! check isoc
     if (isoc /= 0 .and. isoc /=1) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: isoc must be 0 or 1 !'
         write(mystd, *)
         lpass = .false.
     endif
     if (isoc == 1 .and. nband /=3 .and. nband /= 5 .and. nband /=7) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: only support spin-orbital &
                                                  coupling for nband=3, 5, 7 !'
         write(mystd, *)
         lpass = .false.
     endif
  
! check icu
     if (icu /= 1 .and. icu /= 2) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: icu must be 1 or 2 !'
         write(mystd, *)
         lpass = .false.
     endif
     if (icu == 2 .and. nband /= 5 .and. nband /= 7) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: only support Slater-Cordon type &
                                                Coulomb interaction for nband=5, 7 !'
         write(mystd, *)
         lpass = .false.
     endif
  
  
! check Uc, Uv, Jz, Js, Jp, Ud, JH
     if (Uc < zero .or. Uv < zero .or. Jz < zero .or. Js < zero .or. &
                                  Jp < zero .or. Ud < zero .or. JH < zero) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: Uc, Uv, Jz, Js, Jp, Ud, JH &
                                                        must be larger than zero !'
         write(mystd, *)
         lpass = .false.
     endif
  
! check ictqmc
     if (ictqmc /=1 .and. ictqmc /=2 .and. ictqmc /=3 .and. ictqmc /=4 .and. ictqmc /=5) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: ictqmc must be one of 1, 2, 3, 4, 5 !'
         write(mystd, *)
         lpass = .false.
     endif
     if (ictqmc == 3 .and. isoc == 1) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: CTQMC good quantum numbers (N,Sz) &
                           algorithm is NOT supported for spin-orbital coupling case ! '
         write(mystd, *)
         lpass = .false.
     endif
     if (ictqmc == 4 .and. isoc == 1) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: CTQMC good quantum numbers (N,Sz,Ps) &
                              algorithm is NOT supported for spin-orbital coupling case ! '
         write(mystd, *)
         lpass = .false.
     endif
     if (ictqmc == 4 .and. icu == 2) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: CTQMC good quantum numbers (N,Sz,Ps) &
                   algorithm is NOT supported for Slater-Cordon type Coulomb interaction U'
         write(mystd, *)
         lpass = .false.
     endif
     if (ictqmc == 5 .and. isoc == 0) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: CTQMC good quantum numbers (N,Jz) &
                             algorithm is ONLY supported for spin-orbital coupling case !'
         write(mystd, *)
         lpass = .false.
     endif
     if (ictqmc == 5 .and. isoc == 1 .and. icf /= 0) then
         write(mystd, '(2X,a)') 'jasmine >>> ERROR: CTQMC good quantum numbers (N,Jz) &
          algorithm is NOT supported for spin-orbital coupling plus crystal field case !'
         write(mystd, *)
         lpass = .false.
     endif
     
     if (lpass == .true.) then
         write(mystd, '(2X,a)') 'jasmine >>> Good News: all control parameters are OK !'
     else
         call s_print_error('atomic_check_config', 'Found some wrong setting of parameters, &
                                                   please check the "atom.config.in" file !')
     endif
  
     return
  end subroutine atomic_check_config

!!>>> atomic_check_realmat: check whether a matrix is real
  subroutine atomic_check_realmat(ndim, mat, lreal)
     use constants, only : dp, eps6
  
     implicit none
  
! external variables
! dimension of the matrix
     integer, intent(in) :: ndim

! the matrix to be checked
     complex(dp), intent(in) :: mat(ndim, ndim)

! whether Hamiltonian is real
     logical, intent(out) :: lreal
  
! local variables
     integer :: i, j
  
     do i=1, ndim
         do j=1, ndim
             if ( aimag(mat(j,i)) > eps6 ) then
                 lreal = .false. 
                 return
             endif
         enddo
     enddo
  
     lreal = .true.
  
     return
  end subroutine atomic_check_realmat
