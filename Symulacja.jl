using Plots

function area_epidemic_simulation(size, N0, meetings, incubation_time, immunity_time, lockdowns,
    vaccination_day, vaccinations, death_prop, recovery_prop, infection_propability, T)
    # 0 - dead
    # 1 - susceptible
    # 2 - exposed
    # 3 - infected
    # 4 - recovered

    dead = []
    susceptible = collect(1:size^2)
    exposed = []
    infected = []
    recovered = []
    vaccinated = []
    infected_record = [N0]
    population = ones(size, size)
    infection_days = fill(T, size, size)
    recovery_days = fill(T, size, size)
    vaccination_days = fill(T, size, size)

    # Random first infected
    for person in 1:N0
        index = rand(susceptible)
        population[index] = 3
        append!(infected, index)
        filter!(i -> i != index, susceptible)
    end

    # For each day in T days
    anim = @animate for t in 1:T
        infection_prop = infection_propability
        met_today = meetings
        
        # If it's lockdown
        for lockdown in lockdowns
            if lockdown[1] <= t <= lockdown[2]
                infection_prop = infection_prop/2
                met_today = 1
            end
        end

        # Vaccination
        if t >= vaccination_day
            for person in 1:vaccinations
                try
                    index = rand(vcat(susceptible, exposed, recovered))
                    append!(vaccinated, index)
                    filter!(i -> i != index, susceptible)
                    filter!(i -> i != index, exposed)
                    filter!(i -> i != index, recovered)
                catch ArgumentError
                    continue
                end
            end
        end

        # For each person
        for row in 1:size
            for person in 1:size

                index = size*(person-1) + row
                
                # If person is exposed and incubation time has ended, change his status to infected
                if population[index] == 2 && t - infection_days[index] >= incubation_time
                    population[index] = 3
                    append!(infected, index)
                    filter!(i -> i != index, exposed)
                end
                
                # If the person is infected
                if population[row, person] == 3
                    
                    # For each met person from the neighbourhood
                    for met_person in 1:met_today
                        if rand()<infection_prop
                            m = rand(-1:1)
                            n = rand(-1:1)
                            new_infected_index = size * (person + n - 1) + row + m
                            try
                                if population[new_infected_index] == 1 && new_infected_index ∉ vaccinated
                                    population[new_infected_index] = 2
                                    append!(exposed, new_infected_index)
                                    filter!(i -> i != new_infected_index, susceptible)
                                    infection_days[new_infected_index] = t
                                end
                            catch BoundsError
                                continue
                            end
                        end
                    end
                    
                    if rand()<recovery_prop
                        population[index] = 4
                        append!(recovered, index)
                        filter!(i -> i != index, infected)
                        recovery_days[row, person] = t

                    elseif rand()<death_prop
                        population[index] = 0
                        append!(dead, index)
                        filter!(i -> i != index, infected)
                    end
                
                # If person looses immunity
                elseif population[index] == 4 && t - recovery_days[index] >= immunity_time
                    population[index] = 1
                    append!(susceptible, index)
                    filter!(i -> i != index, recovered)
                end
            end
        end
        append!(infected_record, length(infected))
        deaths = length(dead)
        
        heatmap(population,
            title="Day: $t    Deaths: $deaths",
            color=[:black, :gray, :yellow, :orange, :green],
            clim=(0, 4),
            size=(650, 650),
            aspectratio=1
        )
    end
    plot(0:T, infected_record) |> display
    gif(anim, "epidemic.gif", fps=15) |> display
end


size = 100
N0 = 10
meetings = 3
incubation_time = 3
immunity_time = 90
lockdowns = []
vaccination_day = 400
vaccinations = 100
death_prop = 0.001
recovery_prop = 0.05
infection_propability = 0.2
T = 800

area_epidemic_simulation(size, N0, meetings, incubation_time, immunity_time, lockdowns,
        vaccination_day, vaccinations, death_prop, recovery_prop, infection_propability, T)
