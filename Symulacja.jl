function area_epidemic_simulation(size, N0, meetings, infection_progress, loosing_resist_prop, lockdowns,
    vaccine_day, vaccinated, death_prop, recovery_prop, infection_prop, T)
# 0 - dead
# 1 - susceptible
# 2 - exposed
# 3 - infected
# 4 - recovered

deaths = 0
population = ones(size, size)
for person in 1:N0
    population[rand(1:size), rand(1:size)] = 3
end

anim = @animate for t in 1:T
    for row in 1:size
        for person in 1:size
            if population[row, person] == 3
                
                for met_person in 1:meetings
                    if rand()<infection_prop
                        m = rand(-1:1)
                        n = rand(-1:1)
                        try
                            if population[row + m, person + n] == 1
                                population[row + m, person + n] = 3
                            end
                        catch e
                            continue
                        end
                    end
                end
                
                if rand()<recovery_prop
                    population[row, person] = 4
                elseif rand()<death_prop
                    population[row, person] = 0
                    deaths += 1
                end
                
            elseif population[row, person] == 4
                if rand()<loosing_resist_prop
                    population[row, person] = 1
                end
            end
        end
    end
    heatmap(population,
        title="Day: $t    Deaths: $deaths",
        color=[:black, :gray, :yellow, :orange, :green],
        clim=(0, 4),
        size=(700, 700),
        aspectratio=1
    )
end
gif(anim, "epidemic.gif", fps=15) |> display
end
