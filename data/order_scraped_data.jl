using HTTP
using Gumbo
using Cascadia
using CSV
using DataFrames


# Specify the full path to the C
csv_file = "all_tv_series_urls.csv"

# Specify the full path to the /docs directory
docs_path = joinpath(pwd(), "docs")
csv_file_path = joinpath(docs_path, csv_file)


df = DataFrame(
    Name = String[], 
    Genre = String[], 
    Director = String[], 
    Scenarist = String[],
    TopActors = String[],
    Channel = String[],
    Publisher = String[],
    NumberOfSeasons = String[],
    NumberOfEpisodes = String[],
    PublishYear = String[],
    Status = String[]
    )



# extracts data from csv file and performs web scraping
function scrape_tv_data(filename, year, dataframe)
    base_url = "https://tr.wikipedia.org/"
    
    # Defining valid range for publish year
    valid_years = ["1975-1999", "2000-2005"]
    for i in 2006:2023
        push!(valid_years, string(i))
    end

    if !(year in valid_years)
        error("Invalid year: $year. Please provide a valid year.")
    end
    
    # Specifies the path to the CSV file
    csv_filepath = joinpath("docs", filename)
    
    # Read data from the CSV file into a DataFrame
    df = DataFrame(CSV.File(csv_filepath))
    
    # Filter rows where the "Year" column contains the string "1975-1999"
    filtered_df = filter(row -> occursin(year, row.Year), df)

    # Extract values from the "Series" column and store them in an array
    tv_series_urls = String[]
    for row in eachrow(filtered_df)
        push!(tv_series_urls, row.Series)
    end
    
    for url in tv_series_urls
        #Concat the url
        full_url = string(base_url, url)
        #Get the page
        response = HTTP.get(full_url)
        html_content = String(response.body)

        # Parse the HTML content
        parsed_html = parsehtml(html_content)

        # Use CSS selectors to find the element with id 'firstHeading' (name value is there)
        first_heading_selector = Selector("#firstHeading i")

        # Find the element
        first_heading_elements = eachmatch(first_heading_selector, parsed_html.root)

        # Extract name
        if !isempty(first_heading_elements)
            first_heading_element = first(first_heading_elements)
            name = strip(Gumbo.text(first_heading_element))
        else
            name = "Bulunamadı"
        end

        # Selector for the infobox table
        infobox_selector = Selector(".infobox")

        # Find the infobox table
        infobox_table_elements = eachmatch(infobox_selector, parsed_html.root)

        # Function to extract text content from a node
        function extract_text(node)
            return strip(join([text for text in Gumbo.text(node)]))
        end

        # Use dictionary to store extracted information
        extracted_info = Dict()

        # Take the infobox table
        if !isempty(infobox_table_elements)
            infobox_table = first(infobox_table_elements)

            # Iterate over each row in the table
            for row in eachmatch(Selector("tr"), infobox_table)
                label_cells = eachmatch(Selector("th"), row)
                data_cells = eachmatch(Selector("td"), row)

                if !isempty(label_cells) && !isempty(data_cells)
                    label_cell = first(label_cells)
                    data_cell = first(data_cells)

                    label_text = extract_text(label_cell)
                    data_text = ""

                    #Start extracting
                    if label_text in ["Tür", "Senarist", "Yazar", "Yönetmen", "Kanal", "Sezon sayısı", "Bölüm sayısı", "Durumu", "Başrol", "Yapım  şirketi"]
                        links = eachmatch(Selector("a"), data_cell)
                        if label_text == "Başrol" && length(links) >= 3
                            # Extract text from the first three <a> elements in case of Başrol
                            data_text = join(extract_text.(links[1:3]), ", ")
                             
                        elseif !isempty(links)
                            # Extract text from the first <a> element
                            data_text = extract_text(first(links))
                        else
                            # If there is no <a> element in td, extract all text from the data cell
                            data_text = extract_text(data_cell)
                        end
                    end

                    # # Store the values in the dictionary
                    # if data_text != ""
                    extracted_info[label_text] = data_text
                    # end
                end
            end
        end

        # Defining name and year fields
        extracted_info["Dizi İsmi"] = name
        extracted_info["Yayın Yılı"] = year
    
        # Checking if the related field exist on the webpage 
        if !haskey(extracted_info, "Yazar")
            extracted_info["Yazar"] = ""
        end

        if !haskey(extracted_info, "Senarist")
            extracted_info["Senarist"] = ""
        end

        if extracted_info["Yazar"] != "" && extracted_info["Senarist"] != ""
            pop!(extracted_info, "Yazar")
        elseif extracted_info["Yazar"] != "" 
            tmp = extracted_info["Yazar"]
            pop!(extracted_info, "Yazar")
            extracted_info["Senarist"] = tmp
        end

        # Defining CSV fields to write
        extracted_name = haskey(extracted_info, "Dizi İsmi") ? extracted_info["Dizi İsmi"] : ""
        extracted_genre = haskey(extracted_info, "Tür") ? extracted_info["Tür"] : ""
        extracted_scenarist = haskey(extracted_info, "Senarist") ? extracted_info["Senarist"] : ""
        extracted_director = haskey(extracted_info, "Yönetmen") ? extracted_info["Yönetmen"] : ""
        extracted_top_actors = haskey(extracted_info, "Başrol") ? extracted_info["Başrol"] : ""
        extracted_channel = haskey(extracted_info, "Kanal") ? extracted_info["Kanal"] : ""
        extracted_publisher = haskey(extracted_info, "Yapım  şirketi") ? extracted_info["Yapım  şirketi"] : ""
        extracted_n_of_seaons = haskey(extracted_info, "Sezon sayısı") ? extracted_info["Sezon sayısı"] : ""
        extracted_n_of_episodes = haskey(extracted_info, "Bölüm sayısı") ? extracted_info["Bölüm sayısı"] : ""
        extracted_publish_year = haskey(extracted_info, "Yayın Yılı") ? extracted_info["Yayın Yılı"] : ""
        extracted_status = haskey(extracted_info, "Durumu") ? extracted_info["Durumu"] : ""

        # Adding related data to df
        push!(dataframe, [extracted_name, extracted_genre, extracted_director, extracted_scenarist, extracted_top_actors, extracted_channel, 
        extracted_publisher, extracted_n_of_seaons, extracted_n_of_episodes, extracted_publish_year, extracted_status])
    end
end


function save_all_scrape_data()
    years = ["1975-1999", "2000-2005"]
    for i in 2006:2023
        push!(years, string(i))
    end

    # Parses and writes all data to single csv    
    for year in years
        scrape_tv_data(csv_file_path, year , df)
    end

    # Defining file to write
    filename = "all_tv_series.csv"

    # Specify the full path to the /docs directory
    docs_path = joinpath(pwd(), "docs")
    file_path = joinpath(docs_path, filename)
    
    CSV.write(file_path, df)
end

# Scrapes all turkish tv_series data from range 1999-2023 and saves them into a single csv file
save_all_scrape_data()


