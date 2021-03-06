# This file is a part of Julia. License is MIT: http://julialang.org/license

type AmosException <: Exception
    info::Int32
end

## Airy functions

let
    const ai::Array{Float64,1} = Array(Float64,2)
    const ae::Array{Int32,1} = Array(Int32,2)
    global _airy, _biry
    function _airy(z::Complex128, id::Int32, kode::Int32)
        ccall((:zairy_,openspecfun), Void,
              (Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},
               Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32}),
              &real(z), &imag(z),
              &id, &kode,
              pointer(ai,1), pointer(ai,2),
              pointer(ae,1), pointer(ae,2))
        if ae[2] == 0 || ae[2] == 3
            return complex(ai[1],ai[2])
        else
            throw(AmosException(ae[2]))
        end
    end
    function _biry(z::Complex128, id::Int32, kode::Int32)
        ccall((:zbiry_,openspecfun), Void,
              (Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},
               Ptr{Float64}, Ptr{Float64}, Ptr{Int32}),
              &real(z), &imag(z),
              &id, &kode,
              pointer(ai,1), pointer(ai,2),
              pointer(ae,1))
        if ae[1] == 0 || ae[1] == 3  # ignore underflow
            return complex(ai[1],ai[2])
        else
            throw(AmosException(ae[2]))
        end
    end
end

function airy(k::Integer, z::Complex128)
    id = Int32(k==1 || k==3)
    if k == 0 || k == 1
        return _airy(z, id, Int32(1))
    elseif k == 2 || k == 3
        return _biry(z, id, Int32(1))
    else
        throw(ArgumentError("k must be between 0 and 3"))
    end
end

airyprime(z) = airy(1,z)
@vectorize_1arg Number airyprime
airyai(z) = airy(0,z)
@vectorize_1arg Number airyai
airyaiprime(z) = airy(1,z)
@vectorize_1arg Number airyaiprime
airybi(z) = airy(2,z)
@vectorize_1arg Number airybi
airybiprime(z) = airy(3,z)
@vectorize_1arg Number airybiprime

function airyx(k::Integer, z::Complex128)
    id = Int32(k==1 || k==3)
    if k == 0 || k == 1
        return _airy(z, id, Int32(2))
    elseif k == 2 || k == 3
        return _biry(z, id, Int32(2))
    else
        throw(ArgumentError("k must be between 0 and 3"))
    end
end

for afn in (:airy,:airyx)
    @eval begin
        $afn(k::Integer, z::Complex) = $afn(k, float(z))
        $afn{T<:AbstractFloat}(k::Integer, z::Complex{T}) = throw(MethodError($afn,(k,z)))
        $afn(k::Integer, z::Complex64) = Complex64($afn(k, Complex128(z)))

        $afn(k::Integer, x::Real) = $afn(k, float(x))
        $afn(k::Integer, x::AbstractFloat) = real($afn(k, complex(x)))

        $afn(z) = $afn(0,z)
        @vectorize_1arg Number $afn
        @vectorize_2arg Number $afn
    end
end

## Bessel functions

# besselj0, besselj1, bessely0, bessely1
for jy in ("j","y"), nu in (0,1)
    jynu = Expr(:quote, symbol(jy,nu))
    jynuf = Expr(:quote, symbol(jy,nu,"f"))
    bjynu = symbol("bessel",jy,nu)
    if jy == "y"
        @eval begin
            $bjynu(x::Float64) = nan_dom_err(ccall(($jynu,libm),  Float64, (Float64,), x), x)
            $bjynu(x::Float32) = nan_dom_err(ccall(($jynuf,libm), Float32, (Float32,), x), x)
        end
    else
        @eval begin
            $bjynu(x::Float64) = ccall(($jynu,libm),  Float64, (Float64,), x)
            $bjynu(x::Float32) = ccall(($jynuf,libm), Float32, (Float32,), x)
        end
    end
    @eval begin
        $bjynu(x::Real) = $bjynu(float(x))
        $bjynu(x::Complex) = $(symbol("bessel",jy))($nu,x)
        @vectorize_1arg Number $bjynu
    end
end




const cy = Array(Float64,2)
const ae = Array(Int32,2)
const wrk = Array(Float64,2)

function _besselh(nu::Float64, k::Int32, z::Complex128, kode::Int32)
    ccall((:zbesh_,openspecfun), Void,
          (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},
           Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32}),
          &real(z), &imag(z), &nu, &kode, &k, &1,
          pointer(cy,1), pointer(cy,2),
          pointer(ae,1), pointer(ae,2))
    if ae[2] == 0 || ae[2] == 3
        return complex(cy[1],cy[2])
    else
        throw(AmosException(ae[2]))
    end
end

function _besseli(nu::Float64, z::Complex128, kode::Int32)
    ccall((:zbesi_,openspecfun), Void,
          (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},
           Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32}),
          &real(z), &imag(z), &nu, &kode, &1,
          pointer(cy,1), pointer(cy,2),
          pointer(ae,1), pointer(ae,2))
    if ae[2] == 0 || ae[2] == 3
        return complex(cy[1],cy[2])
    else
        throw(AmosException(ae[2]))
    end
end

function _besselj(nu::Float64, z::Complex128, kode::Int32)
    ccall((:zbesj_,openspecfun), Void,
          (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},
           Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32}),
          &real(z), &imag(z), &nu, &kode, &1,
          pointer(cy,1), pointer(cy,2),
          pointer(ae,1), pointer(ae,2))
    if ae[2] == 0 || ae[2] == 3
        return complex(cy[1],cy[2])
    else
        throw(AmosException(ae[2]))
    end
end

function _besselk(nu::Float64, z::Complex128, kode::Int32)
    ccall((:zbesk_,openspecfun), Void,
          (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},
           Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32}),
          &real(z), &imag(z), &nu, &kode, &1,
          pointer(cy,1), pointer(cy,2),
          pointer(ae,1), pointer(ae,2))
    if ae[2] == 0 || ae[2] == 3
        return complex(cy[1],cy[2])
    else
        throw(AmosException(ae[2]))
    end
end

function _bessely(nu::Float64, z::Complex128, kode::Int32)
    ccall((:zbesy_,openspecfun), Void,
          (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32},
           Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32},
           Ptr{Float64}, Ptr{Float64}, Ptr{Int32}),
          &real(z), &imag(z), &nu, &kode, &1,
          pointer(cy,1), pointer(cy,2),
          pointer(ae,1), pointer(wrk,1),
          pointer(wrk,2), pointer(ae,2))
    if ae[2] == 0 || ae[2] == 3
        return complex(cy[1],cy[2])
    else
        throw(AmosException(ae[2]))
    end
end

function besselh(nu::Float64, k::Integer, z::Complex128)
    if nu < 0
        s = (k == 1) ? 1 : -1
        return _besselh(-nu,Int32(k),z,Int32(1)) * complex(cospi(nu),-s*sinpi(nu))
    end
    return _besselh(nu,Int32(k),z,Int32(1))
end

function besselhx(nu::Float64, k::Integer, z::Complex128)
    if nu < 0
        s = (k == 1) ? 1 : -1
        return _besselh(-nu,Int32(k),z,Int32(2)) * complex(cospi(nu),-s*sinpi(nu))
    end
    return _besselh(nu,Int32(k),z,Int32(2))
end

function besseli(nu::Float64, z::Complex128)
    if nu < 0
        return _besseli(-nu,z,Int32(1)) - 2_besselk(-nu,z,Int32(1))*sinpi(nu)/pi
    else
        return _besseli(nu,z,Int32(1))
    end
end

function besselix(nu::Float64, z::Complex128)
    if nu < 0
        return _besseli(-nu,z,Int32(2)) - 2_besselk(-nu,z,Int32(2))*exp(-abs(real(z))-z)*sinpi(nu)/pi
    else
        return _besseli(nu,z,Int32(2))
    end
end

function besselj(nu::Float64, z::Complex128)
    if nu < 0
        return _besselj(-nu,z,Int32(1))*cospi(nu) + _bessely(-nu,z,Int32(1))*sinpi(nu)
    else
        return _besselj(nu,z,Int32(1))
    end
end

besselj(nu::Cint, x::Float64) = ccall((:jn, libm), Float64, (Cint, Float64), nu, x)
besselj(nu::Cint, x::Float32) = ccall((:jnf, libm), Float32, (Cint, Float32), nu, x)


function besseljx(nu::Float64, z::Complex128)
    if nu < 0
        return _besselj(-nu,z,Int32(2))*cospi(nu) + _bessely(-nu,z,Int32(2))*sinpi(nu)
    else
        return _besselj(nu,z,Int32(2))
    end
end

besselk(nu::Float64, z::Complex128) = _besselk(abs(nu), z, Int32(1))

besselkx(nu::Float64, z::Complex128) = _besselk(abs(nu), z, Int32(2))

function bessely(nu::Cint, x::Float64)
    if x < 0
        throw(DomainError())
    end
    ccall((:yn, libm), Float64, (Cint, Float64), nu, x)
end
function bessely(nu::Cint, x::Float32)
    if x < 0
        throw(DomainError())
    end
    ccall((:ynf, libm), Float32, (Cint, Float32), nu, x)
end

function bessely(nu::Float64, z::Complex128)
    if nu < 0
        return _bessely(-nu,z,Int32(1))*cospi(nu) - _besselj(-nu,z,Int32(1))*sinpi(nu)
    else
        return _bessely(nu,z,Int32(1))
    end
end

function besselyx(nu::Float64, z::Complex128)
    if nu < 0
        return _bessely(-nu,z,Int32(2))*cospi(nu) - _besselj(-nu,z,Int32(2))*sinpi(nu)
    else
        return _bessely(nu,z,Int32(2))
    end
end


function besseli(nu::Real, x::AbstractFloat)
    if x < 0 && !isinteger(nu)
        throw(DomainError())
    end
    real(besseli(float(nu), complex(x)))
end

function besselix(nu::Real, x::AbstractFloat)
    if x < 0 && !isinteger(nu)
        throw(DomainError())
    end
    real(besselix(float(nu), complex(x)))
end

function besselj(nu::Real, x::AbstractFloat)
    if isinteger(nu)
        if typemin(Cint) <= nu <= typemax(Cint)
            return besselj(Cint(nu), x)
        end
    elseif x < 0
        throw(DomainError())
    end
    real(besselj(float(nu), complex(x)))
end

function besseljx(nu::Real, x::AbstractFloat)
    if x < 0 && !isinteger(nu)
        throw(DomainError())
    end
    real(besseljx(float(nu), complex(x)))
end

function besselk(nu::Real, x::AbstractFloat)
    if x < 0
        throw(DomainError())
    elseif x == 0
        return oftype(x, Inf)
    end
    real(besselk(float(nu), complex(x)))
end

function besselkx(nu::Real, x::AbstractFloat)
    if x < 0
        throw(DomainError())
    elseif x == 0
        return oftype(x, Inf)
    end
    real(besselkx(float(nu), complex(x)))
end

function bessely(nu::Real, x::AbstractFloat)
    if x < 0
        throw(DomainError())
    elseif isinteger(nu) && typemin(Cint) <= nu <= typemax(Cint)
        return bessely(Cint(nu), x)
    end
    real(bessely(float(nu), complex(x)))
end

function besselyx(nu::Real, x::AbstractFloat)
    if x < 0
        throw(DomainError())
    end
    real(besselyx(float(nu), complex(x)))
end

for f in ("i", "ix", "j", "jx", "k", "kx", "y", "yx")
    bfn = symbol("bessel", f)
    @eval begin
        $bfn(nu::Real, x::Real) = $bfn(nu, float(x))
        function $bfn(nu::Real, z::Complex)
            Tf = promote_type(float(typeof(nu)),float(typeof(real(z))))
            $bfn(Tf(nu), Complex{Tf}(z))
        end
        $bfn{T<:AbstractFloat}(k::T, z::Complex{T}) = throw(MethodError($bfn,(k,z)))
        $bfn(nu::Float32, x::Complex64) = Complex64($bfn(Float64(nu), Complex128(x)))
        @vectorize_2arg Number $bfn
    end
end


for bfn in (:besselh, :besselhx)
    @eval begin
        $bfn(nu, z) = $bfn(nu, 1, z)
        $bfn(nu::Real, k::Integer, x::Real) = $bfn(nu, k, float(x))
        $bfn(nu::Real, k::Integer, x::AbstractFloat) = $bfn(float(nu), k, complex(x))

        function $bfn(nu::Real, k::Integer, z::Complex)
            Tf = promote_type(float(typeof(nu)),float(typeof(real(z))))
            $bfn(Tf(nu), k, Complex{Tf}(z))
        end

        $bfn{T<:AbstractFloat}(nu::T, k::Integer, z::Complex{T}) = throw(MethodError($bfn,(nu,k,z)))
        $bfn(nu::Float32, k::Integer, x::Complex64) = Complex64($bfn(Float64(nu), k, Complex128(x)))
        @vectorize_2arg Number $bfn
    end
end


hankelh1(nu, z) = besselh(nu, 1, z)
@vectorize_2arg Number hankelh1

hankelh2(nu, z) = besselh(nu, 2, z)
@vectorize_2arg Number hankelh2

hankelh1x(nu, z) = besselhx(nu, 1, z)
@vectorize_2arg Number hankelh1x

hankelh2x(nu, z) = besselhx(nu, 2, z)
@vectorize_2arg Number hankelh2x
