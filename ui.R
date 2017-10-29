#Load and process data
source("data_cleaning.R")

#Load necessary libraries
library(shinydashboard)
library(ggplot2)
library(plotly)
library(DT)

#Body element
body <- dashboardBody(tabItems(
  tabItem(tabName = "barplot",
          h2("Barchart"),
          fluidRow(
            column(
              width = 9,
              box(
                collapsible = TRUE,
                width = 12,
                status = "primary",
                plotlyOutput('plot1')
              )
            ),
            column(
              width = 3,
              box(
                collapsible = TRUE,
                width = 12,
                status = "warning",
                selectInput(
                  "xcolp1",
                  "Select dataset",
                  c(
                    "Average rating" = "avg_rating",
                    "Total movies" = "total_movies",
                    "Total votes" = "total_votes"
                  )
                )
              ),
              box(
                collapsible = TRUE,
                width = 12,
                status = "primary",
                infoBoxOutput("p1max", width = 12),
                infoBoxOutput("p1mean", width = 12),
                infoBoxOutput("p1min", width = 12)
              )
            )
          )),
  tabItem(
    tabName = "piechart",
    h2("Piechart"),
    box(
      collapsible = TRUE,
      width = 9,
      status = "primary",
      plotlyOutput('plot2')
    ),
    box(
      collapsible = TRUE,
      width = 3,
      status = "warning",
      selectInput("datasetp2", "Select dataset", unique(datasets$name)),
      selectInput("xcolp2", "Select variable", c("Total movies", "Total votes"))
    )
    
    
  ),
  tabItem(
    tabName = "timechart",
    h2("Timechart"),
    box(
      collapsible = TRUE,
      status = "primary",
      width = 9,
      plotlyOutput('plot3')
    ),
    box(
      collapsible = TRUE,
      status = "warning",
      width = 3,
      selectInput(
        "genrep3",
        "Select genre",
        unique(genres$name),
        multiple = TRUE,
        selected = "Crime"
      ),
      selectInput("datasetp3", "Select dataset", unique(datasets$name))
    )
  ),
  tabItem(tabName = "dataexplorer",
          h2("Data Explorer"),
          fluidPage(
            tabBox(
              width = 9,
              title = "",
              tabPanel("Genre's",
                       DT::dataTableOutput("datatable1")),
              tabPanel("Movies",
                       DT::dataTableOutput("datatable2"))
            )
          ))
))

#Ui element
ui <- dashboardPage(
  skin = "green",
  dashboardHeader(title = "Movie genre charts", titleWidth = 300),
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "sidebar",
      menuItem(
        "Barchart",
        tabName = "barplot",
        icon = icon("bar-chart-o")
      ),
      menuItem("Piechart", tabName = "piechart", icon = icon("pie-chart")),
      menuItem(
        "Timechart",
        tabName = "timechart",
        icon = icon("line-chart")
      ),
      menuItem("Data Explorer", tabName = "dataexplorer", icon = icon("table"))
    )
  ),
  body
)