using HTTP
using Gumbo
using Cascadia
using CSV, DataFrames


# Function to extract text content from a node
function extract_text(node)
    return strip(join([text for text in Gumbo.text(node)]))
end


# scrape urls of tv series
function scrape_tv_series(url) 
    # Fetch the HTML content of the webpage
    response = HTTP.get(url)
    html_content = String(response.body)

    # Parse the HTML content
    parsed_html = parsehtml(html_content)

    # Use CSS selectors to find all tables
    tables = eachmatch(Selector("table"), parsed_html.root)

    # Initialize two arrays to store the series titles and links
    series_links = []
    # series_titles = []

    # Iterate over each table
    for table in tables
        # Iterate over each row in the table
        for row in eachmatch(Selector("tr"), table)
            # Find the first cell in the row
            cells = eachmatch(Selector("td"), row)
            if length(cells) > 0
                first_cell = cells[1]
                # Find the first link in the cell
                links = eachmatch(Selector("a"), first_cell)
                if length(links) > 0
                    link = links[1]
                    # Extract the link in href from the link
                    if haskey(link.attributes, "href")
                        href = link.attributes["href"]
                        push!(series_links, href)
                    end
                end
            end
        end
    end
    return series_links
end


url = "https://tr.wikipedia.org/wiki/T%C3%BCrk_dizileri_listesi"
tv_series_all  = scrape_tv_series(url)

# turkish tv series of last 25 year

tv_series_1975_1999 = tv_series_all[961:1023]
tv_series_2000_2005 = tv_series_all[899:960]
tv_series_2006 = tv_series_all[874:898]
tv_series_2007 = tv_series_all[841:873]
tv_series_2008 = tv_series_all[807:840]
tv_series_2009 = tv_series_all[785:806]
tv_series_2010 = tv_series_all[759:784]
tv_series_2011 = tv_series_all[727:758]
tv_series_2012 = tv_series_all[692:726]
tv_series_2013 = tv_series_all[649:691]
tv_series_2014 = tv_series_all[607:648]
tv_series_2015 = tv_series_all[565:606]
tv_series_2016 = tv_series_all[518:564]
tv_series_2017 = tv_series_all[453:517]
tv_series_2018 = tv_series_all[405:452]
tv_series_2019 = tv_series_all[363:404]
tv_series_2020 = tv_series_all[315:362]
tv_series_2021 = tv_series_all[232:314]
tv_series_2022 = tv_series_all[155:231]
tv_series_2023 = tv_series_all[65:154]

function save_series_to_single_csv(series_list, year, df)
    for series in series_list
        push!(df, [series, year])
    end
end
df = DataFrame(Series = String[], Year = String[])



# Her yıl aralığı için ayrı dosyalara kaydetme
save_series_to_single_csv(tv_series_1975_1999, "1975-1999", df)
save_series_to_single_csv(tv_series_2000_2005, "2000-2005", df)
save_series_to_single_csv(tv_series_2006, "2006", df)
save_series_to_single_csv(tv_series_2007, "2007", df)
save_series_to_single_csv(tv_series_2008, "2008", df)
save_series_to_single_csv(tv_series_2009, "2009", df)
save_series_to_single_csv(tv_series_2010, "2010", df)
save_series_to_single_csv(tv_series_2011, "2011", df)
save_series_to_single_csv(tv_series_2012, "2012", df)
save_series_to_single_csv(tv_series_2013, "2013", df)
save_series_to_single_csv(tv_series_2014, "2014", df)
save_series_to_single_csv(tv_series_2015, "2015", df)
save_series_to_single_csv(tv_series_2016, "2016", df)
save_series_to_single_csv(tv_series_2017, "2017", df)
save_series_to_single_csv(tv_series_2018, "2018", df)
save_series_to_single_csv(tv_series_2019, "2019", df)
save_series_to_single_csv(tv_series_2020, "2020", df)
save_series_to_single_csv(tv_series_2021, "2021", df)
save_series_to_single_csv(tv_series_2022, "2022", df)
save_series_to_single_csv(tv_series_2023, "2023", df)

# Assuming df is your DataFrame containing TV series data
csv_filename = "all_tv_series.csv"

# Specify the full path to the /docs directory
docs_path = joinpath(pwd(), "docs")
csv_filepath = joinpath(docs_path, csv_filename)

# Ensure the /docs directory exists or create it
if !isdir(docs_path)
    mkdir(docs_path)
end

# Write to CSV file in the /docs directory only if it doesn't exist
if !isfile(csv_filepath)
    CSV.write(csv_filepath, df)
    println("Data has been written to $csv_filepath.")
else
    println("CSV file $csv_filepath already exists. Skipping write operation.")
end






