!!!-----------------------------------------------------------------------
!!! project : jasmine
!!! program : atomic_make_foccu
!!!           atomic_make_ffmat
!!!           atomic_make_fhmat
!!! source  : atomic_full.f90
!!! type    : subroutines
!!! author  : yilin wang (email: qhwyl2006@126.com)
!!! history : 07/09/2014 by yilin wang
!!!           08/22/2014 by yilin wang
!!!           10/20/2014 by li huang
!!! purpose : computational subroutines for the calculations of occupation
!!!           number, F-matrix, and atomic Hamiltonian in full Fock space.
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!>>> atomic_make_foccu: make occupancy for atomic eigenstates in full
!!>>> Hilbert space case
  subroutine atomic_make_foccu()
     use constants, only: zero, one

     use control, only: norbs, ncfgs
     use m_full, only: bin_basis
     use m_full, only: occu, eigvec

     implicit none

! local variables
! loop index over orbits
     integer :: iorb

! loop index over configurations
     integer :: ibas

! evaluate occupancy in the Fock basis
     occu = zero
     do ibas=1,ncfgs
         do iorb=1,norbs
             if (bin_basis(iorb,ibas) == 1) then
                 occu(ibas,ibas) = occu(ibas,ibas) + one
             endif ! back if (bin_basis(iorb,ibas) == 1) block
         enddo ! over iorb={1,norbs} loop
     enddo ! over ibas={1,ncfgs} loop

! transform the occupancy from Fock basis to atomic eigenbasis
     call atomic_tran_repr_real(ncfgs, occu, eigvec)

     return
  end subroutine atomic_make_foccu

!!>>> atomic_make_ffmat: make F-matrix for annihilation operators in
!!>>> full Hilbert space case
  subroutine atomic_make_ffmat()
     use control, only : norbs, ncfgs
     use m_full, only : dec_basis, index_basis
     use m_full, only : fmat, eigvec

     implicit none

! local variables
! loop index
     integer :: i
     integer :: j
     integer :: k

! left Fock state
     integer :: left

! right Fock state
     integer :: right

! the sign change
     integer :: isgn

! evaluate F-matrix in the Fock basis
     do i=1,norbs
         do j=1,ncfgs
             right = dec_basis(j)
             if (btest(right,i-1) .eqv. .true.) then
                call atomic_make_c(i, right, left, isgn)
                k = index_basis(left)
                fmat(k,j,i) = dble(isgn)
             endif ! back if (btest(right,i-1) .eqv. .true.) block
         enddo ! over j={1,ncfgs} loop
     enddo ! over i={1,norbs} loop

! rotate fmat from Fock basis to the atomic eigenvector basis
     do i=1,norbs
         call atomic_tran_repr_real(ncfgs, fmat(:,:,i), eigvec)
     enddo ! over i={1,norbs} loop

     return
  end subroutine atomic_make_ffmat

!!>>> atomic_make_fhmat: make atomic Hamiltonian in the full Hilbert space
  subroutine atomic_make_fhmat()
     use constants, only : czero, epst

     use control, only : norbs, ncfgs
     use m_full, only : dec_basis, index_basis, bin_basis
     use m_full, only : hmat
     use m_spmat, only : emat, umat

     implicit none

! local variables
! loop index
     integer :: i
     integer :: ibas
     integer :: jbas
     integer :: alpha, betta
     integer :: delta, gamma

! sign change due to fermion anti-commute relation
     integer :: sgn

! new atomic state after fermion operators act
     integer :: knew

! binary code form of an atomic state
     integer :: code(norbs)

! start to make Hamiltonian
! initialize hmat
     hmat = czero

! first, two fermion operator terms
     do jbas=1,ncfgs
         alploop: do alpha=1,norbs
             betloop: do betta=1,norbs

                 sgn = 0
                 knew = dec_basis(jbas)
                 code(1:norbs) = bin_basis(1:norbs,jbas)

! impurity level is too small
                 if ( abs(emat(alpha,betta)) .lt. epst ) CYCLE

! simulate one annihilation operator
                 if ( code(betta) == 1 ) then
                     do i=1,betta-1
                         if ( code(i) == 1 ) sgn = sgn + 1
                     enddo ! over i={1,betta-1} loop
                     code(betta) = 0

! simulate one creation operator
                     if ( code(alpha) == 0 ) then
                         do i=1,alpha-1
                             if (code(i) == 1) sgn = sgn + 1
                         enddo ! over i={1,alpha-1} loop
                         code(alpha) = 1

! determine the row number and hamiltonian matrix elememt
                         knew = knew - 2**(betta-1)
                         knew = knew + 2**(alpha-1)
                         sgn  = mod(sgn,2)
                         ibas = index_basis(knew)
                         if ( ibas == 0 ) then
                             call s_print_error('atomic_make_fhmat','error while determining row!')
                         endif ! back if ( ibas == 0 ) block
                         hmat(ibas,jbas) = hmat(ibas,jbas) + emat(alpha,betta) * (-1.0d0)**sgn
                     endif ! back if (code(alpha) == 0) block
                 endif ! back if (code(betta) == 1) block

             enddo betloop ! over betta={1,norbs} loop
         enddo alploop ! over alpha={1,norbs} loop
     enddo ! over jbas={1,ncfgs} loop

! second, four fermion operator terms (coulomb interaction)
     do jbas=1,ncfgs
         alphaloop : do alpha=1,norbs
             bettaloop : do betta=1,norbs
                 deltaloop : do delta=1,norbs
                     gammaloop : do gamma=1,norbs

                         sgn  = 0
                         knew = dec_basis(jbas)
                         code(1:norbs) = bin_basis(1:norbs, jbas)

                         if ( ( alpha == betta ) .or. ( delta == gamma ) ) CYCLE
                         if ( abs(umat(alpha,betta,delta,gamma)) < epst ) CYCLE

! simulate two annihilation operators
                         if ( ( code(delta) == 1 ) .and. ( code(gamma) == 1 ) ) then
                             do i=1,gamma-1
                                 if (code(i) == 1) sgn = sgn + 1
                             enddo ! over i={1,gamma-1} loop
                             code(gamma) = 0
                             do i=1,delta-1
                                 if (code(i) == 1) sgn = sgn + 1
                             enddo ! over i={1,delta-1} loop
                             code(delta) = 0

! simulate two creation operator
                             if ( ( code(alpha) == 0 ) .and. ( code(betta) == 0 ) ) then
                                 do i=1,betta-1
                                     if ( code(i) == 1 ) sgn = sgn + 1
                                 enddo ! over i={1,betta-1} loop
                                 code(betta) = 1
                                 do i=1,alpha-1
                                     if ( code(i) == 1 ) sgn = sgn + 1
                                 enddo ! over i={1,alpha-1} loop
                                 code(alpha) = 1

! determine the row number and hamiltonian matrix elememt
                                 knew = knew - 2**(gamma-1) - 2**(delta-1)
                                 knew = knew + 2**(betta-1) + 2**(alpha-1)
                                 sgn  = mod(sgn,2)
                                 ibas = index_basis(knew)
                                 if ( ibas == 0 ) then
                                     call s_print_error('atomic_make_fhmat','error while determining row')
                                 endif ! back if ( ibas == 0 ) block
                                 hmat(ibas,jbas) = hmat(ibas,jbas) + umat(alpha,betta,delta,gamma) * (-1.0d0)**sgn
                             endif ! back if ( ( code(delta) == 1 ) .and. ( code(gamma) == 1 ) ) block
                         endif ! back if ( ( code(alpha) == 0 ) .and. ( code(betta) == 0 ) ) block

                     enddo gammaloop ! over gamma={1,norbs} loop
                 enddo deltaloop ! over delta={1,norbs} loop
             enddo bettaloop ! over betta={1,norbs} loop
         enddo alphaloop ! over alpha={1,norbs} loop
     enddo ! over jbas={1,ncfgs} loop

     return
  end subroutine atomic_make_fhmat