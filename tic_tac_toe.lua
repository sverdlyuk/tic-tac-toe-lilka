-- Хрестики-нулики для платформи Lilka

-- Константи кольорів
WHITE = display.color565(255, 255, 255)
BLACK = display.color565(0, 0, 0)
GRAY = display.color565(128, 128, 128)
HIGHLIGHT = display.color565(0, 255, 0)  -- Зелений колір для виділення
RED = display.color565(255, 0, 0)  -- Червоний колір для повідомлення про вихід
BLUE = display.color565(0, 0, 255)  -- Синій колір для рахунку
CORAL = display.color565(255, 127, 80) -- Кораловий колір для O

-- Ініціалізація глобальних змінних
grid = {{" ", " ", " "}, {" ", " ", " "}, {" ", " ", " "}}  -- Тепер глобальна
current_player = "X"  -- Глобальна
selected = {x = 1, y = 1}  -- Глобальна
game_over = false  -- Глобальна
winner = nil  -- Глобальна
selection_animation = 0  -- Глобальна
exit_confirmation = false  -- Змінна для підтвердження виходу
score = {X = 0, O = 0}  -- Рахунок гравців

-- Функція перевірки переможця
function check_winner()
    -- Перевірка рядків
    for i = 1, 3 do
        if grid[i][1] ~= " " and grid[i][1] == grid[i][2] and grid[i][2] == grid[i][3] then
            return grid[i][1]
        end
    end

    -- Перевірка стовпців
    for j = 1, 3 do
        if grid[1][j] ~= " " and grid[1][j] == grid[2][j] and grid[2][j] == grid[3][j] then
            return grid[1][j]
        end
    end

    -- Перевірка діагоналей
    if grid[1][1] ~= " " and grid[1][1] == grid[2][2] and grid[2][2] == grid[3][3] then
        return grid[1][1]
    end
    if grid[1][3] ~= " " and grid[1][3] == grid[2][2] and grid[2][2] == grid[3][1] then
        return grid[1][3]
    end

    -- Перевірка на нічию
    for i = 1, 3 do
        for j = 1, 3 do
            if grid[i][j] == " " then
                return nil -- Є порожня клітинка, гра триває
            end
        end
    end

    return "draw" -- Якщо всі клітинки заповнені
end

-- Функція скидання гри (без обнулення рахунку)
function reset_game()
    grid = {{" ", " ", " "}, {" ", " ", " "}, {" ", " ", " "}}
    current_player = "X"
    selected = {x = 1, y = 1}
    game_over = false
    winner = nil
    selection_animation = 0
    exit_confirmation = false
end

-- Функція повного скидання гри з рахунком
function full_reset()
    reset_game()
    score = {X = 0, O = 0}
end

-- Покращена функція для ходу штучного інтелекту (з випадковістю)
function ai_move()
    -- 1. Перевірка на перемогу: чи може AI виграти своїм ходом
    for i = 1, 3 do
        for j = 1, 3 do
            if grid[i][j] == " " then
                grid[i][j] = "O"
                if check_winner() == "O" then
                    return
                end
                grid[i][j] = " " -- Скасувати хід
            end
        end
    end

    -- 2. Блокування гравця: чи може гравець виграти своїм наступним ходом
    -- Додано випадковість: іноді AI "не помічає" загрозу
    if math.random() > 0.3 then
        for i = 1, 3 do
            for j = 1, 3 do
                if grid[i][j] == " " then
                    grid[i][j] = "X"
                    if check_winner() == "X" then
                        grid[i][j] = "O" -- Заблокувати хід гравця
                        return
                    end
                    grid[i][j] = " " -- Скасувати хід
                end
            end
        end
    end

    -- 3. Пріоритет центральної клітинки
    if grid[2][2] == " " then
        grid[2][2] = "O"
        return
    end

    -- 4. Пріоритет кутів (випадковий вибір)
    local corners = {{1, 1}, {1, 3}, {3, 1}, {3, 3}}
    for _, corner in ipairs(corners) do
        local i, j = corner[1], corner[2]
        if grid[i][j] == " " and math.random() > 0.5 then
            grid[i][j] = "O"
            return
        end
    end

    -- 5. Якщо нічого з вищезазначеного не спрацювало, вибрати першу доступну клітинку
    for i = 1, 3 do
        for j = 1, 3 do
            if grid[i][j] == " " then
                grid[i][j] = "O"
                return
            end
        end
    end
end

-- Основний цикл оновлення гри
function lilka.update(delta)
    -- Оновлення анімації виділення
    selection_animation = (selection_animation + delta * 4) % (2 * math.pi)
    
    -- Отримуємо стан контролера
    local state = controller.get_state()
    
    -- Перевірка кнопки виходу (D)
    if state.d.just_pressed then
        if not exit_confirmation then
            -- Перше натискання - показуємо підтвердження
            exit_confirmation = true
        end
        return
    end
    
    -- Підтвердження виходу при натисканні A
    if exit_confirmation and state.a.just_pressed then
        util.exit()
        return
    end
    
    -- Скасування виходу при натисканні B
    if exit_confirmation and state.b.just_pressed then
        exit_confirmation = false
        return
    end
    
    -- Якщо показується підтвердження виходу, не обробляємо інші дії
    if exit_confirmation then
        return
    end
    
    if not game_over then
        if current_player == "X" then
            -- Обробка введення для гравця
            if state.up.just_pressed then
                selected.y = selected.y - 1
                if selected.y < 1 then selected.y = 3 end
            elseif state.down.just_pressed then
                selected.y = selected.y + 1
                if selected.y > 3 then selected.y = 1 end
            elseif state.left.just_pressed then
                selected.x = selected.x - 1
                if selected.x < 1 then selected.x = 3 end
            elseif state.right.just_pressed then
                selected.x = selected.x + 1
                if selected.x > 3 then selected.x = 1 end
            elseif state.a.just_pressed then
                if grid[selected.y][selected.x] == " " then
                    grid[selected.y][selected.x] = "X"
                    current_player = "O"

                    -- Перевірка на перемогу
                    winner = check_winner()
                    if winner then
                        game_over = true
                        if winner ~= "draw" then
                            score[winner] = score[winner] + 1
                            if winner == "O" then
                                play_loss_sound()  -- Відтворення сумного звуку, якщо виграв "O"
                            elseif winner == "X" then
                                play_win_sound()  -- Відтворення радісного звуку, якщо виграв "X"
                            end
                        end
                    end
                end
            end
        elseif current_player == "O" then
            -- Хід штучного інтелекту
            ai_move()
            current_player = "X"

            -- Перевірка на перемогу
            winner = check_winner()
            if winner then
                game_over = true
                if winner ~= "draw" then
                    score[winner] = score[winner] + 1
                    if winner == "O" then
                        play_loss_sound()  -- Відтворення сумного звуку, якщо виграв "O"
                    elseif winner == "X" then
                        play_win_sound()  -- Відтворення радісного звуку, якщо виграв "X"
                    end
                end
            end
        end
    else
        -- Перезапуск гри при натисканні кнопки B
        if state.b.just_pressed then
            reset_game()
        end
    end
end

-- Функція для анімації перекреслення виграшної лінії
function animate_winning_line()
    if winner and winner ~= "draw" then
        local color = winner == "X" and HIGHLIGHT or CORAL
        local line_thickness = 5
        local cell_size = 40
        local offset_x = (display.width - cell_size * 3) / 2
        local offset_y = (display.height - cell_size * 3) / 2

        -- Перевірка рядків
        for i = 1, 3 do
            if grid[i][1] == winner and grid[i][2] == winner and grid[i][3] == winner then
                local y = offset_y + (i - 1) * cell_size + cell_size / 2
                display.fill_rect(offset_x, y - line_thickness / 2, cell_size * 3, line_thickness, color)
                return
            end
        end

        -- Перевірка стовпців
        for j = 1, 3 do
            if grid[1][j] == winner and grid[2][j] == winner and grid[3][j] == winner then
                local x = offset_x + (j - 1) * cell_size + cell_size / 2
                display.fill_rect(x - line_thickness / 2, offset_y, line_thickness, cell_size * 3, color)
                return
            end
        end

        -- Перевірка діагоналей
        if grid[1][1] == winner and grid[2][2] == winner and grid[3][3] == winner then
            display.draw_line(
                offset_x,
                offset_y,
                offset_x + cell_size * 3,
                offset_y + cell_size * 3,
                color
            )
            return
        end

        if grid[1][3] == winner and grid[2][2] == winner and grid[3][1] == winner then
            display.draw_line(
                offset_x + cell_size * 3,
                offset_y,
                offset_x,
                offset_y + cell_size * 3,
                color
            )
            return
        end
    end
end

-- Виправлення викликів функцій draw_x і draw_o
function draw_x(x, y, size)
    local color = HIGHLIGHT -- Зелений для хрестика
    display.draw_line(x - size, y - size, x + size, y + size, color)
    display.draw_line(x - size, y + size, x + size, y - size, color)
end

function draw_o(x, y, size)
    local color = CORAL -- Кораловий для нулика
    display.draw_circle(x, y, size, color)
end

-- Функція для відтворення сумного звуку програшу
function play_loss_sound()
    -- Мелодія "ту-ту-ду" (сумний звук програшу)
    local melody = {
        {220, 4},  -- Низький тон (220 Гц) на 1/4
        {180, 4},  -- Ще нижчий тон (180 Гц) на 1/4
        {150, 2},  -- Найнижчий тон (150 Гц) на 1/2
    }
    buzzer.play_melody(melody, 60)  -- Відтворюємо мелодію з темпом 60 ударів на хвилину
end

-- Функція для відтворення радісної мелодії виграшу
function play_win_sound()
    -- Мелодія "до-мі-соль" (радісний звук виграшу)
    local melody = {
        {523, 4},  -- Нота "до" (523 Гц) на 1/4
        {659, 4},  -- Нота "мі" (659 Гц) на 1/4
        {784, 2},  -- Нота "соль" (784 Гц) на 1/2
    }
    buzzer.play_melody(melody, 120)  -- Відтворюємо мелодію з темпом 120 ударів на хвилину
end

-- Функція малювання гри
function lilka.draw()
    display.fill_screen(BLACK)
    
    -- Якщо показується підтвердження виходу
    if exit_confirmation then
        -- Встановлюємо колір тексту перед виведенням
        display.set_text_color(RED)
        display.set_cursor(display.width/2 - 80, display.height/2 - 20)
        display.print("Вийти з гри?")
        
        -- Встановлюємо колір для другого рядка
        display.set_text_color(WHITE)
        display.set_cursor(display.width/2 - 120, display.height/2 + 10)
        display.print("A - так, B - ні")
        return
    end
    
    -- Малювання рахунку зліва екрану (більш компактно)
    display.set_text_color(WHITE)
    
    -- Відображення рахунку X
    draw_x(15, 60, 5, WHITE)
    display.set_cursor(25, 60)
    display.print(": " .. score.X)
    
    -- Відображення рахунку O
    draw_o(15, 80, 5, WHITE)
    display.set_cursor(25, 80)
    display.print(": " .. score.O)
    
    -- Видалено текст "SELECT обнулит"
    
    -- Малювання сітки
    local cell_size = 40
    local offset_x = (display.width - cell_size * 3) / 2
    local offset_y = (display.height - cell_size * 3) / 2
    
    for i = 1, 3 do
        for j = 1, 3 do
            local x = offset_x + (j-1) * cell_size + cell_size/2
            local y = offset_y + (i-1) * cell_size + cell_size/2
            
            -- Рамка клітинки
            display.draw_rect(
                x - cell_size/2, 
                y - cell_size/2, 
                cell_size, 
                cell_size, 
                WHITE
            )
            
            -- Відображення X або O
            if grid[i][j] == "X" then
                draw_x(x, y, 10, WHITE)
            elseif grid[i][j] == "O" then
                draw_o(x, y, 10, WHITE)
            end
            
            -- Покращене підсвічування вибраної клітинки
            if selected.x == j and selected.y == i and not game_over then
                -- Пульсуюче виділення
                local pulse = (math.sin(selection_animation) + 1) / 2
                local highlight_size = cell_size + 4 + (pulse * 4)
                
                -- Малюємо рамку виділення
                display.draw_rect(
                    x - highlight_size/2,
                    y - highlight_size/2,
                    highlight_size,
                    highlight_size,
                    HIGHLIGHT
                )
                
                -- Малюємо кутові елементи виділення
                local corner_size = 5
                -- Верхній лівий кут
                display.fill_rect(
                    x - cell_size/2 - 2,
                    y - cell_size/2 - 2,
                    corner_size,
                    corner_size,
                    HIGHLIGHT
                )
                -- Верхній правий кут
                display.fill_rect(
                    x + cell_size/2 - corner_size + 2,
                    y - cell_size/2 - 2,
                    corner_size,
                    corner_size,
                    HIGHLIGHT
                )
                -- Нижній лівий кут
                display.fill_rect(
                    x - cell_size/2 - 2,
                    y + cell_size/2 - corner_size + 2,
                    corner_size,
                    corner_size,
                    HIGHLIGHT
                )
                -- Нижній правий кут
                display.fill_rect(
                    x + cell_size/2 - corner_size + 2,
                    y + cell_size/2 - corner_size + 2,
                    corner_size,
                    corner_size,
                    HIGHLIGHT
                )
            end
        end
    end
    
    -- Відображення статусу гри
    display.set_text_color(WHITE)
    if game_over then
        animate_winning_line() -- Додано виклик анімації
        if winner == "draw" then
            display.set_cursor(display.width/2 - 30, display.height - 40)
            display.print("Нічия!")
        else
            display.set_cursor(display.width/2 - 60, display.height - 40)
            display.print("Переміг гравець ")
            
            -- Ще більше вправо, щоб не накладалося на слово "гравець"
            if winner == "X" then
                draw_x(display.width/2 + 105, display.height - 43, 5, WHITE)
            else
                draw_o(display.width/2 + 105, display.height - 43, 5, WHITE)
            end
        end
        -- Змінено на коротший текст "B - грати знову"
        display.set_cursor(display.width/2 - 50, display.height - 20)
        display.print("B - грати знову")
    else
        display.set_cursor(display.width/2 - 60, display.height - 20)
        display.print("Хід гравця: ")
        
        -- Відображення символу поточного гравця - ще правіше і вище
        if current_player == "X" then
            draw_x(display.width/2 + 55, display.height - 23, 5, WHITE)
        else
            draw_o(display.width/2 + 55, display.height - 23, 5, WHITE)
        end
    end
    
    -- Додаємо підказку про кнопку виходу
    display.set_text_color(WHITE)
    display.set_cursor(10, 30)
    display.print("D - вихід")
end
