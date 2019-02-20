using SFGTools
using Test
using DataFrames
using SFGTools
using Random
import Statistics: mean

const SAMPLE_DATA_DIR = joinpath(@__DIR__, "sampledata/")

function listtest()
    grab(SAMPLE_DATA_DIR; getall=true)
    grab(SAMPLE_DATA_DIR)
    df = list_spectra()
    @test size(df,1) == 123
    df = list_spectra(date=(2018,2,15))
    @test size(df,1) == 118
    df = list_spectra(inexact="HDT")
    @test size(df,1) == 78
    df = list_spectra(exact="HDT_180109A_EksplaScan_FR")
    @test size(df,1) == 25
    df = list_spectra(group=true)
    @test size(df,1) == 12
end

function loadtest()
    spectrum = load_spectra(63654390286607)
    @test typeof(spectrum) == Array{SFGTools.SFSpectrum,1}
    @test spectrum[1][1] == 702.0
    @test load_spectra(63685681406436, format=:tiff) ==
          load_spectra(63685681406436, format=:sif)
    spectrum
end

function attribute_test(spectrum)
    meta = get_metadata(spectrum)
    @test typeof(meta) == Dict{String,Any}
    attr = get_attribute(spectrum, "ccd_exposure_time")
    @test attr == Any[0.5, 0.5, 0.5, 0.5, 0.5]
end

function fieldcorrection_test()
    a = Array{Float64,3}(undef, (4, 1, 2))
    a[:,1,1] = [6, 7, 8, 9]
    a[:,1,2] = [6, 8, 9, 7]
    spectrum = SFSpectrum(0, a)

    b = Array{Float64,3}(undef, (4, 1, 2))
    b[:,1,1] = [0, 1, 3, 0]
    b[:,1,2] = [2, 1, 1, 0]
    bias = SFSpectrum(0, b)

    d = Array{Float64,3}(undef, (4, 1, 2))
    d[:,1,1] = [3, 4, 3, 5]
    d[:,1,2] = [4, 2, 1, 5]
    dark = SFSpectrum(0, d)

    f = Array{Float64,3}(undef, (4, 1, 2))
    f[:,1,1] = [2, 3, 4, 3]
    f[:,1,2] = [4, 3, 6, 1]
    flat = SFSpectrum(0, f)

    l = Array{Float64,3}(undef, (4, 1, 2))
    l[:,1,1] = [1, 2, 3, 0]
    l[:,1,2] = [3, 2, 3, 2]
    darkflat = SFSpectrum(0, l)

    fieldcorrection!(spectrum, bias=bias, dark=dark, flat=flat, darkflat=darkflat)

    @test spectrum[:,1,1] == [5.0, 8.0,  6.0, 8.0]
    @test spectrum[:,1,2] == [5.0, 10.0, 7.0, 4.0]

    fieldcorrection!(spectrum, dark=dark)

    @test spectrum[:,1,1] == [1.5, 5.0, 4.0, 3.0]
    @test spectrum[:,1,2] == [1.5, 7.0, 5.0, -1.0]
end

function rm_events_test()
    a = rand(MersenneTwister(0), 50)
    a[19:20] .*= 5
    a[22] *= 40
    num_removed_events = rm_events!(a, minstd=2)
    @test num_removed_events == 2
end

function average_test()
    a = Array{Float64,3}(undef, (4, 1, 2))
    a[:,1,1] = [6, 7, 8, 9]
    a[:,1,2] = [6, 8, 9, 7]
    spectrum1 = SFSpectrum(63654399800782, a)

    b = Array{Float64,3}(undef, (4, 1, 3))
    b[:,1,1] = [0, 1, 3, 0]
    b[:,1,2] = [2, 1, 1, 0]
    b[:,1,3] = [4, 1, 2, 0]
    spectrum2 = SFSpectrum(63654399800782, b)


    spectrum = average(spectrum1)
    @test spectrum[:,1,1] == [6.0, 7.5,  8.5, 8.0]

    spectrum = average(spectrum1, combine = false)
    @test spectrum[:,1,1] == [6, 7, 8, 9]
    @test spectrum[:,1,2] == [6, 8, 9, 7]

    spectrum = average(spectrum2)
    @test spectrum[:,1,1] == [2.0, 1.0, 2.0, 0]

    spectrum = average(spectrum2, combine = false)
    @test spectrum[:,1,1] == [0, 1, 3, 0]
    @test spectrum[:,1,2] == [2, 1, 1, 0]
    @test spectrum[:,1,3] == [4, 1, 2, 0]
end



# function save_mat_test(spectra)
#     success = false
#     try
#         save_mat(tempname(), spectra)
#         success = true
#     catch
#         success = false
#     end
#     @test success == true
# end

function makespectraarray(spectrum::SFSpectrum)
    spectra = Array{SFSpectrum,1}(undef, size(spectrum,2))
    for i = 1:size(spectrum, 2)
        spectra[i] = SFSpectrum(spectrum.id, spectrum[:,i,1])
    end
    spectra
end


@testset "list_spectra Tests" begin listtest() end
@testset "load_spectra Tests" begin global spectrum = loadtest()[1] end
@testset "Attribute Tests" begin attribute_test(spectrum) end
@testset "Fieldcorrection Tests" begin fieldcorrection_test() end
@testset "Event Removal Tests" begin rm_events_test() end
@testset "average Test" begin average_test() end
# spectra = makespectraarray(spectrum)
# @testset "MAT Saving" begin save_mat_test(spectra) end
