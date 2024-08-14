using CSV
using DataFrames
using Flux
using Statistics
using CategoricalArrays
using Random
using Crayons
using BSON

# Dosya yolları ve isimlerini tanımlama
filename = "2017_models.csv"
model_name = "model_2017_1.bson"

# Mevcut dizinin yolunu ve dosyayı okuma yolu ayarlama
current_dir = @__DIR__
dir = joinpath(current_dir, "..", "data", "docs", "models")
file_to_read = joinpath(dir, filename)

df = CSV.read(file_to_read, DataFrame) # CSV dosyasını DataFrame olarak okuma

# Kategorik değişkenleri sayısallaştırma fonksiyonu
function encode_categorical(df, column_name)
    lowercased_array = lowercase.(df[!, column_name])  # Tüm stringleri küçük harfe çevir
    cat_array = categorical(lowercased_array)
    levels_dict = Dict(level => index for (index, level) in enumerate(levels(cat_array)))
    return [levels_dict[value] for value in lowercased_array]
end

# DataFrame sütunlarını sayısallaştırma
df[!, :Actor1] = encode_categorical(df, :Actor1)
df[!, :Actor2] = encode_categorical(df, :Actor2)
df[!, :Actor3] = encode_categorical(df, :Actor3)
df[!, :Genre] = encode_categorical(df, :Genre)
df[!, :Director] = encode_categorical(df, :Director)
df[!, :Scenarist] = encode_categorical(df, :Scenarist)
df[!, :Channel] = encode_categorical(df, :Channel)
df[!, :Publisher] = encode_categorical(df, :Publisher)

# Oyuncuların etkisini bir özellikte birleştirme
df[!, :ActorsEffect] = (df[!, :Actor1] + df[!, :Actor2] + df[!, :Actor3]) / 3

# Giriş ve çıkış verilerini hazırlama
X = Matrix(df[!, [:Genre, :Director, :Scenarist, :Channel, :Publisher, :PublishYear, :ActorsEffect]])
y = Vector(df[!, :NumberOfSeasons])

# Verileri Float32 tipine dönüştürme
X = Float32.(X)
y = Float32.(y)

# Veri setini karıştırma ve eğitim/test olarak ayırma
indices = shuffle(1:size(X, 1))
split_index = floor(Int, length(indices) * 0.8)
train_indices = indices[1:split_index]
test_indices = indices[(split_index + 1):end]
X_train = X[train_indices, :]
y_train = y[train_indices]
X_test = X[test_indices, :]
y_test = y[test_indices]

# Model yapısını tanımlama
model = Chain(
    Dense(size(X, 2), 64, relu),  # İlk katman, 64 nöron
    Dense(64, 32, relu),          # İkinci katman, 32 nöron
    Dense(32, 1)                  # Çıkış katmanı
) # relu aktivasyon fonksiyonu, modelin doğrusal olmayan öğrenme yeteneğini artırır. 
#relu, negatif değerler için 0 döndürürken, pozitif değerler için girdi değerini olduğu gibi döndürür.

# Kayıp fonksiyonu ve optimizasyon algoritmasını tanımlama
loss(x, y) = Flux.mse(model(x), y) # Modelin performansını değerlendirmek için kullanılan bir kayıp fonksiyonunu tanımlar.
optimizer = ADAM(0.001) # Modelin eğitimi sırasında ağırlıklarını güncellemek için kullanılacak optimizasyon algoritmasını tanımlar.
# Eğitim sürecinde, modelin kayıp fonksiyonunu minimize etmeye çalışırken ağırlıklarını ADAM algoritması ile günceller. 
# Bu süreç, modelin veri üzerindeki tahminlerinin gerçeğe ne kadar yakın olduğunu sürekli olarak iyileştirir.

# Eğitim verilerini hazırlama
data = [(X_train', y_train')]

# Modeli eğitme
epochs = 10000 
for epoch in 1:epochs
    for (x, y) in data
        gs = gradient(() -> loss(x, y), Flux.params(model))
        Flux.Optimise.update!(optimizer, Flux.params(model), gs)
    end
end

# Test verisi üzerinde tahmin yapma ve MSE hesaplama
predictions = model(X_test')
test_mse = Flux.mse(predictions, y_test')
println("Test Mean Squared Error: $test_mse")

# Modeli kaydetme
model_dir = joinpath(current_dir, "..", "models") 
model_file_path = joinpath(model_dir, model_name)

BSON.@save model_file_path model X_test y_test df test_indices


