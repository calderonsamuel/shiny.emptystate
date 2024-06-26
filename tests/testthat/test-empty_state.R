describe("EmptyStateManager", {
  it("should be R6 & EmptyStateManager class", {
    test_class <- EmptyStateManager$new("test_id")
    expect_true(R6::is.R6(test_class))
    expect_s3_class(test_class, "EmptyStateManager")
  })

  it("should initialize with is_empty_state_show FALSE", {
    test_class <- EmptyStateManager$new("test_id")
    expect_false(test_class$is_empty_state_show())
  })

  it("should contain default_empty_state_component when no content is passed", {
    test_class <- EmptyStateManager$new("test_id")
    expect_equal(
      test_class$.__enclos_env__$private$.html_content,
      as.character(default_empty_state_component())
    )
  })

  it("should contain passed color", {
    test_class <- EmptyStateManager$new("test_id", color = "navy")
    expect_equal(test_class$.__enclos_env__$private$.color, "navy")
  })

  it("checks if manager class object cannot be modified (class should be locked)", {
    test_class <- EmptyStateManager$new("test_id")
    expect_error(test_class$new_member <- 1)
    expect_error(test_class$is_empty_state_show <- function() TRUE)
    expect_error(test_class$hide <- function() FALSE)
    expect_error(test_class$show <- function() TRUE)
  })

  it("checks the empty state component is visible when triggered", {
    skip_on_cran()
    expected_div <-
      "<div class=\"empty-state-content\"><div class=\"myDiv\"></div></div>"
    app <- shinytest2::AppDriver$new(test_app(), name = "test")
    app$click("show")
    expect_equal(
      app$get_html(selector = ".empty-state-content"),
      as.character(expected_div)
    )
    app$stop()
  })

  it("checks the empty state component is hidden when not triggered", {
    skip_on_cran()
    app <- shinytest2::AppDriver$new(test_app(), name = "test")
    expect_null(app$get_html(selector = ".empty-state-content"))
    app$stop()
  })

  it("checks the empty state component is hidden when triggered", {
    skip_on_cran()
    app <- shinytest2::AppDriver$new(test_app(), name = "test")
    app$click("show")
    app$click("hide")
    expect_null(app$get_html(selector = ".empty-state-content"))
    app$stop()
  })

  it("uses a default z-index for its container when not specified", {
    skip_on_cran()
    app <- shinytest2::AppDriver$new(test_app(), name = "test")
    app$click("show")

    js_get_z_index <- "function getZIndex() {
        const container = document.querySelector('.empty-state-container');
      return window.getComputedStyle(container).zIndex;
      };

      getZIndex();"

    expect_equal(app$get_js(js_get_z_index), "9999")
    app$stop()
  })

  it("can use an arbitrary z-index value for its container", {
    skip_on_cran()

    test_app <- function() {
      shiny::shinyApp(
        ui = shiny::fluidPage(
          use_empty_state(),
          shiny::actionButton("show", "Show empty state!"),
          shiny::actionButton("hide", "Hide empty state!"),
          shiny::tableOutput("my_table")
        ),
        server = function(input, output) {
          empty_state_content <- htmltools::div(class = "myDiv")
          empty_state_manager <- EmptyStateManager$new(
            id = "my_table",
            html_content = empty_state_content,
            z_index = 3
          )
          shiny::observeEvent(input$show, {
            empty_state_manager$show()
          })
          shiny::observeEvent(input$hide, {
            empty_state_manager$hide()
          })
          output$my_table <- shiny::renderTable(data.frame(NA))
        }
      )
    }


    app <- shinytest2::AppDriver$new(test_app(), name = "test")
    app$click("show")

    js_get_z_index <- "function getZIndex() {
        const container = document.querySelector('.empty-state-container');
      return window.getComputedStyle(container).zIndex;
      };

      getZIndex();"

    expect_equal(app$get_js(js_get_z_index), "3")
    app$stop()
  })
})

describe("use_empty_state()", {
  test_func <- use_empty_state()
  src_files <- list(
    "emptystate.css",
    "emptystate.js"
  )

  it("should add source files properly", {
    expect <- paste0(
      '<link href=\"/', src_files[[1]],
      '\" rel=\"stylesheet\" />\n<script src=\"/',
      src_files[[2]], '\"></script>'
    )
    test_dep <- htmltools::renderDependencies(list(test_func))
    expect_equal(!!as.character(test_dep), !!expect)
  })

  it("should add dependencies properly", {
    expect_equal(test_func$name, "shiny.emptystate")
    expect_equal(test_func$package, "shiny.emptystate")
    expect_equal(test_func$script, src_files[[2]])
    expect_equal(test_func$stylesheet, src_files[[1]])
  })
})
