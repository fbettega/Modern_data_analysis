plot_win_rate_mat <- function(
    Df_winrate_format,
    group_column,
    Cut_of_number_of_data = 0,
    simplify_tab_ratio = 0,
    only_signif = FALSE,
    tiles_size = 1,
    size_multiplier = 5) {
  marges <- list(
    l = 0, # marge gauche
    r = 50, # marge droite (par exemple)
    b = 50, # marge basse (par exemple)
    t = 50 # marge haute (par exemple)
  )
  
  
  Df_winrate_format_filter_base <- Df_winrate_format %>%
    filter(number_of_games > 0) %>%
    # filtre surement a déplacé pour opti
    filter(Archetype != Matchups_OpponentArchetype) %>%
    filter(!!rlang::sym(paste0("number_of_", group_column)) > Cut_of_number_of_data)
  
  if (only_signif) {
    Df_winrate_format_filter_base <- Df_winrate_format_filter_base %>%
      filter(!!rlang::sym(paste0("CI_WR_sign_diff_0_", group_column)))
  }
  
  
  
  Df_winrate_format_filter <- Df_winrate_format_filter_base %>%
    group_by(Archetype) %>%
    mutate(
      ratio_matchup_arch = n() / (length(unique(Df_winrate_format_filter_base$Archetype)) - 1)
    ) %>%
    ungroup() %>%
    group_by(Matchups_OpponentArchetype) %>%
    mutate(
      ratio_matchup_oppoarch = n() / (length(unique(Df_winrate_format_filter_base$Matchups_OpponentArchetype)) - 1)
    ) %>%
    ungroup() %>%
    filter(ratio_matchup_arch >= simplify_tab_ratio) %>%
    filter(ratio_matchup_oppoarch >= simplify_tab_ratio) %>%
    select(-ratio_matchup_arch, -ratio_matchup_oppoarch) %>%
    group_by(Archetype) %>%
    mutate(
      Archetype_presence_matches = sum(number_of_matches),
      Archetype_presence_games = sum(number_of_games),
      Archetype_WR_matches = winrate_1_data(sum(Win_matches), sum(number_of_matches - Win_matches)),
      Archetype_CI_WR_matches = CI_prop(Archetype_WR_matches, Archetype_presence_matches),
      Archetype_CI_WR_format_matches = paste0(
        round(Archetype_WR_matches * 100, 1),
        "%",
        formating_CI(
          Archetype_WR_matches,
          Archetype_CI_WR_matches,
          round_val = 1, limit = c(0, 1)
        )
      ),
      Archetype_WR_games = winrate_1_data(sum(Matchups_Wins), sum(Matchups_Losses)),
      Archetype_CI_WR_games = CI_prop(Archetype_WR_games, Archetype_presence_games),
      Archetype_CI_WR_format_games = paste0(
        round(Archetype_WR_games * 100, 1),
        "%",
        formating_CI(
          Archetype_WR_games,
          Archetype_CI_WR_games,
          round_val = 1, limit = c(0, 1)
        )
      )
    ) %>%
    select(
      -Archetype_WR_games, -Archetype_CI_WR_games,
      -Archetype_WR_matches, -Archetype_CI_WR_matches
    ) %>%
    ungroup() %>%
    group_by(Matchups_OpponentArchetype) %>%
    mutate(
      oppo_Archetype_presence_matches = sum(number_of_matches),
      oppo_Archetype_presence_games = sum(number_of_games),
      oppo_Archetype_WR_matches = winrate_1_data(sum(number_of_matches - Win_matches), sum(Win_matches)),
      oppo_Archetype_CI_WR_matches = CI_prop(oppo_Archetype_WR_matches, oppo_Archetype_presence_matches),
      oppo_Archetype_CI_WR_format_matches = paste0(
        round(oppo_Archetype_WR_matches * 100, 1),
        "%",
        formating_CI(
          oppo_Archetype_WR_matches,
          oppo_Archetype_CI_WR_matches,
          round_val = 1, limit = c(0, 1)
        )
      ),
      oppo_Archetype_WR_games = winrate_1_data(sum(Matchups_Wins), sum(Matchups_Losses)),
      oppo_Archetype_CI_WR_games = CI_prop(oppo_Archetype_WR_games, oppo_Archetype_presence_games),
      oppo_Archetype_CI_WR_format_games = paste0(
        round(oppo_Archetype_WR_games * 100, 1),
        "%",
        formating_CI(
          oppo_Archetype_WR_games,
          oppo_Archetype_CI_WR_games,
          round_val = 1, limit = c(0, 1)
        )
      )
    ) %>%
    select(
      -oppo_Archetype_WR_games, -oppo_Archetype_CI_WR_games,
      -oppo_Archetype_WR_matches, -oppo_Archetype_CI_WR_matches
    ) %>%
    ungroup()
  
  
  
  label_x <- paste0(
    "<span style='font-size:", 17 - size_multiplier, "px;'> <b>",
    Df_winrate_format_filter %>%
      pull(Archetype) %>%
      unique(),
    "</b> </span>",
    "<br /> n : ", Df_winrate_format_filter %>%
      select(Archetype, all_of(paste0("Archetype_presence_", group_column))) %>%
      distinct() %>%
      pull(
        !!rlang::sym(paste0("Archetype_presence_", group_column))
      ),
    "<br /> ", Df_winrate_format_filter %>%
      pull(
        !!rlang::sym(paste0("Archetype_CI_WR_format_", group_column))
      ) %>%
      unique()
  )
  
  
  label_y <- paste0(
    "<span style='font-size:", 17 - size_multiplier, "px;'> <b>",
    Df_winrate_format_filter %>%
      pull(Archetype) %>%
      unique(),
    "</b> </span>",
    "<br /> n : ", Df_winrate_format_filter %>%
      select(Archetype, all_of(paste0("Archetype_presence_", group_column))) %>%
      distinct() %>%
      pull(
        !!rlang::sym(paste0("Archetype_presence_", group_column))
      ),
    "<br /> ", Df_winrate_format_filter %>%
      pull(
        !!rlang::sym(paste0("Archetype_CI_WR_format_", group_column))
      ) %>%
      unique()
  )
  
  
  
  
  if (nrow(Df_winrate_format_filter) > 0){
    plot_base_en_cours <- 
      ggplot(
        Df_winrate_format_filter,
        aes(
          Matchups_OpponentArchetype,
          Archetype,
          fill = !!rlang::sym(paste0("WR_", group_column)),
          text = paste(
            "Win rate of ", Archetype, " vs ", Matchups_OpponentArchetype, "<br>", # Archetype name
            !!rlang::sym(paste0("number_format_", group_column)), "<br>",
            "(",
            !!rlang::sym(paste0("CI_WR_sign_", group_column)), ") ",
            !!rlang::sym(paste0("CI_WR_format_", group_column)), "<br>",
            sep = ""
          )
        )
      ) +
      geom_tile(
        color = "white",
        stat = "identity",
        height = tiles_size,
        width = tiles_size
      ) +
      scale_fill_gradient2(
        midpoint = 0.5, low = "red", mid = "white",
        high = "green", space = "Lab"
      ) +
      geom_text(
        aes(
          Matchups_OpponentArchetype,
          Archetype,
          label = ifelse(
            !!rlang::sym(paste0("CI_WR_sign_diff_0_", group_column)),
            paste0(
              "<b>",
              round(
                !!rlang::sym(paste0("WR_", group_column)) * 100,
                1
              ),
              "</b>"
            ),
            round(!!rlang::sym(paste0("WR_", group_column)) * 100, 1)
          )
        ),
      ) +
      scale_x_discrete(
        label = rev(label_x),
        # guide = guide_axis(n.dodge=3)
      ) +
      scale_y_discrete(
        label = label_y,
        # sec.axis = dup_axis()
        # guide = guide_axis(n.dodge = 2)
      ) 
    
    
    signif_dataframe <- Df_winrate_format_filter %>%
      filter(
        !!rlang::sym(paste0("CI_WR_sign_diff_0_", group_column))
      )
    
    
    
    if (nrow(signif_dataframe) > 0){
      plot_signif_en_cours <- plot_base_en_cours +
        geom_tile(
          data =
            signif_dataframe,
          aes(
            Matchups_OpponentArchetype,
            Archetype
          ),
          fill = "transparent",
          colour = "black",
          size = 1
        )
    } else {
      plot_signif_en_cours <- plot_base_en_cours 
    }
    
    plot_en_cours <- (
      plot_signif_en_cours  +
        theme(
          axis.title = element_blank(),
          legend.position = "none",
          panel.border = element_blank(),
          panel.grid.major = element_blank(),
          axis.text.x = element_text(angle = 315)
        ) 
    ) %>%
      ggplotly(
        tooltip = c("text"),
        height = (480 * size_multiplier), width = (640 * size_multiplier)
      ) %>%
      plotly::layout(margin = marges)
  } else {
    plot_en_cours <- NULL
  }
  
  
  
  return(plot_en_cours)
}