

# Here is where the visual parts are created (rshiny)
#--------------------------------------------------------------------------------------------------------------------
function(input, output, session) {
  #Reactive
  #------------------------------------------------------------------------------------------------------------------
  
  #Creating reactive object for graphs
  genre.ratings <- reactive({
    if (input$xcolp1 == "avg_rating") {
      genre.movies %>%
        group_by(genre, dataset) %>%
        summarize(y = round(mean(rating), 2))
    } else if (input$xcolp1 == "total_votes") {
      genre.movies %>%
        group_by(genre, dataset) %>%
        summarize(y = sum(votes))
    } else if (input$xcolp1 == "total_movies") {
      genre.movies %>%
        group_by(genre, dataset) %>%
        summarize(y = n())
    }
  })
  
  #Creating reactive object for graphs
  genre.ratings.yearly <- reactive({
    genre.movies %>%
      filter(dataset == input$datasetp3 &
               genre %in% input$genrep3) %>%
      group_by(genre, dataset, year) %>%
      summarize(
        avg_rating = mean(rating),
        total_movies = n(),
        total_votes = sum(votes)
      )
  })
  
  #Rendering
  #------------------------------------------------------------------------------------------------------------------
  
  #Rendering first plot
  output$plot1 <- renderPlotly({
    ggplot(
      genre.ratings(),
      aes(genre, y, fill = dataset),
      position = "group",
      xlab = input$xcolp1
    ) +
      geom_col(position = "dodge",
               stat = "identity",
               width = 0.8) +
      theme(axis.text.x = element_text(
        angle = 45,
        hjust = 1,
        vjust = 0.5
      )) +
      labs(y = input$xcolp1)
  })
  
  #Rendering datatable: genre.ratings
  output$datatable1 = DT::renderDataTable({
    table1 <- genre.movies %>%
      group_by(genre, dataset) %>%
      summarize(
        avg_rating = round(mean(rating), 2),
        total_movies = n(),
        total_votes = sum(votes)
      )
    
    datatable(table1,
              filter = 'top',
              options = list(pageLength = 10, autoWidth = TRUE))
  })
  
  #Rendering datatable: genre.movies
  output$datatable2 = DT::renderDataTable({
    datatable(
      genre.movies,
      filter = 'top',
      options = list(pageLength = 10, autoWidth = TRUE)
    )
  })
  
  #Rendering piechart
  observeEvent({
    input$datasetp2
    input$xcolp2
  }, {
    if (input$xcolp2 == "Total votes") {
      pie <- genre.movies %>%
        filter(dataset == input$datasetp2) %>%
        group_by(genre) %>%
        summarize(y = sum(votes))
    }
    else if (input$xcolp2 == "Total movies") {
      pie <- genre.movies %>%
        filter(dataset == input$datasetp2) %>%
        group_by(genre) %>%
        summarize(y = n())
    }
    
    output$plot2 <- renderPlotly(plot_ly(
      labels = pie$genre,
      values = pie$y,
      type = 'pie'
    ))
  })
  
  #Rendering Timelapse chart
  output$plot3 <- renderPlotly({
    p <-
      ggplot(data = genre.ratings.yearly(),
             aes(
               x = year,
               y = avg_rating,
               group = genre,
               color = genre,
               size = 1
             )) +
      geom_line(alpha = 0.5) +
      geom_point(aes(frame = year, size = total_movies)) +
      theme(axis.text.x = element_text(
        angle = 45,
        hjust = 1,
        vjust = 0.5
      ))
    
    p <- ggplotly(p)
  })
  
  #Updating mean, max, min
  observeEvent({
    input$xcolp1
  }, {
    info <- genre.movies %>%
      group_by(genre, dataset) %>%
      summarize(
        avg_rating = round(mean(rating), 2),
        total_movies = n(),
        total_votes = sum(votes)
      )
    
    result.min <- info[which.min(unlist(info[, input$xcolp1])), ]
    result.max <- info[which.max(unlist(info[, input$xcolp1])), ]
    
    output$p1min <- renderInfoBox({
      infoBox(
        result.min$genre,
        paste(result.min[, input$xcolp1]),
        icon = icon("chevron-down"),
        color = "red"
      )
    })
    
    output$p1max <- renderInfoBox({
      infoBox(
        result.max$genre,
        paste(result.max[, input$xcolp1]),
        icon = icon("chevron-up"),
        color = "green"
      )
    })
    
    output$p1mean <- renderInfoBox({
      infoBox("Mean",
              round(colMeans(info[, input$xcolp1]), 2),
              icon = icon("minus"),
              color = "blue")
    })
  })
}
