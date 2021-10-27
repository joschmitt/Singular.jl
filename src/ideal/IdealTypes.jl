###############################################################################
#
#   IdealSet/sideal
#
###############################################################################

const IdealSetID = Dict{PolyRing, Set}()

mutable struct IdealSet{T <: AbstractAlgebra.NCRingElem} <: Set
   base_ring::PolyRingUnion

   function IdealSet{T}(R::PolyRing) where T
      return get!(IdealSetID, R) do
         new(R)
      end
   end
end

mutable struct sideal{T <: AbstractAlgebra.NCRingElem} <: Set
   ptr::libSingular.ideal_ptr
   base_ring::PolyRingUnion
   isGB::Bool
   isTwoSided::Bool

   function sideal{T}(R::PolyRingUnion, id::libSingular.ideal_ptr, isGB::Bool, isTwoSided::Bool) where T
      z = new{T}(id, R, isGB, isTwoSided)
      R.refcount += 1
      finalizer(_sideal_clear_fn, z)
      return z
   end
end

function _sideal_clear_fn(I::sideal{T}) where T <: SPolyUnion
   R = I.base_ring
   libSingular.id_Delete(I.ptr, R.ptr)
   _PolyRing_clear_fn(R)
end

isdefault_twosided_ideal(R::PolyRing) = true
isdefault_twosided_ideal(R::LPRing) = true
isdefault_twosided_ideal(R::PluralRing) = false

isdefault_twosided_ideal(::Type{<:spoly}) = true
isdefault_twosided_ideal(::Type{<:slpalg}) = true
isdefault_twosided_ideal(::Type{<:spluralg}) = false

function sideal{S}(R::PolyRingUnion, id::libSingular.ideal_ptr, isGB::Bool) where S
   return sideal{S}(R, id, isGB, isdefault_twosided_ideal(S))
end

function sideal{S}(R::PolyRingUnion, id::libSingular.ideal_ptr) where S
   return sideal{S}(R, id, false, isdefault_twosided_ideal(S))
end

function sideal{S}(R::PolyRingUnion, ids::Vector{<:SPolyUnion}, isTwoSided::Bool) where S
   n = length(ids)
   id = libSingular.idInit(Cint(n), 1)
   for i = 1:n
      p = libSingular.p_Copy(ids[i].ptr, R.ptr)
      libSingular.setindex_internal(id, p, Cint(i - 1))
   end
   return sideal{S}(R, id, false, isTwoSided)
end

function sideal{T}(R::PolyRingUnion, ids::SPolyUnion...) where T
   n = length(ids)
   id = libSingular.idInit(Cint(n), 1)
   for i = 1:n
      p = libSingular.p_Copy(ids[i].ptr, R.ptr)
      libSingular.setindex_internal(id, p, Cint(i - 1))
   end
   return sideal{T}(R, id, false, isdefault_twosided_ideal(R))
end

