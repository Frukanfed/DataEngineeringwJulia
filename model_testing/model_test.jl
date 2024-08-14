using CSV
using DataFrames
using Flux
using Statistics
using CategoricalArrays
using Random
using Crayons
using BSON

# Set the right path for model file
current_dir = @__DIR__
models_dir = joinpath(current_dir, "..", "models")
model_file_path = joinpath(models_dir, "model_2021.bson")

# Load the model and test data
BSON.@load model_file_path model X_test y_test df test_indices

# Define functions for categorization and processing predictions
function categorize_prediction(prediction)
    if prediction < 1.5
        return "Başarısız"
    elseif prediction < 2.5
        return "Kısmen Başarılı"
    elseif prediction < 5.5
        return "Başarılı"
    elseif prediction < 10.5
        return "Kısmen Olgun"
    else
        return "Olgun"
    end
end

function process_prediction(prediction)
    processed_pred = max(round(prediction), 1)
    return Int(processed_pred)
end

# Initialize variables for cumulative difference and correct predictions count
global toplam_fark = 0
global dogru_tahmin_sayisi = 0

# Arrays to store predictions and actual values for correlation analysis
tahminler = Float64[]
gercekler = Float64[]

# Evaluate the model's predictions
for i in 1:length(test_indices)
    index = test_indices[i]
    xi = reshape(X_test[i, :], :, 1)
    pred = model(xi)
    processed_pred = process_prediction(pred[1])
    dizi_adi = df[index, :Name]
    category = categorize_prediction(processed_pred)
    actual_seasons = df[index, :NumberOfSeasons]

    println("Dizi: $dizi_adi, Tahmin edilen sezon sayısı: $processed_pred, Kategori: $category")
    println(Crayon(foreground=:red), "Dizi: $dizi_adi, Gerçek sezon sayısı: $actual_seasons", Crayon(foreground=:default))

    fark = abs(processed_pred - actual_seasons)
    global toplam_fark += fark
    if processed_pred == actual_seasons
        global dogru_tahmin_sayisi += 1
    end

    push!(tahminler, pred[1])
    push!(gercekler, y_test[i])
end

# Calculate the average difference and success rate
ortalama_fark = toplam_fark / length(test_indices)
basari_orani = dogru_tahmin_sayisi / length(test_indices)

# Calculate the correlation between predictions and actual values
korelasyon = cor(tahminler, gercekler)

println("Ortalama Fark: $ortalama_fark")
println("Doğru Tahmin Oranı: $basari_orani")
println("Tahminler ve Gerçek Değerler Arasındaki Korelasyon: $korelasyon")
