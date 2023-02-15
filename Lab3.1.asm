global _start   ; начало программы
section .bss    ; объявляем неиницализированные переменные
 powered resd 1 ; двойное слово для результата
 strOutput resb 9   ; 9 байт (или меньше) для вывода

section .data   ; объявляем остальные переменные и
        ; сообщения
 n db 0, 0  ; основание степени 
 m db 0 ; показатель степени
 repetitionsNumber db 0 ; число повторений внешнего цикла
 resultLength db 0      ; длина результата

 msgOK db 'Numbers are OK', 0xA ; на вход получены цифры
 lenOK equ $ -msgOK         ; и его длина

 msgSuccess db 'n to the power of m is : '  ; успешно выполнено
 lenSuccess equ $ - msgSuccess          ; и его длина
 
 msgError db 'bad input'    ; на вход получены не цифры
 lenError equ $ -msgError ; и его длина
 
 nIsZero db '0 is 0 in any power.'  ; n - ноль
 lennIsZero equ $ -nIsZero      ; и его длина
 
 nIsOne db '1 is 1 in any power.'   ; n - единица
 lennIsOne equ $ -nIsOne        ; и его длина
 
 mIsZero db 'anything is 1 in 0 power.' ; m - ноль
 lenmIsZero equ $-mIsZero           ; и его длина

section .text
 _start:

 mov eax, 3 ;}
 mov ebx, 0 ;}
 mov ecx, n ;}
 mov edx, 2 ;}
 int 0x80   ;}
        ;} ввод m и n с клавиатуры
 mov eax, 3 ;}
 mov ebx, 0 ;}
 mov ecx, m ;}
 mov edx, 1 ;}
 int 0x80   ;}

areOK: ; проверка на то, что m и n - цифры
 cmp byte [n], 48
 jl error
 cmp byte [n], 57
 jg error
 cmp byte [m], 48
 jl error
 cmp byte [m], 57
 jg error

 mov eax, 4     ;}
 mov ebx, 1     ;}
 mov ecx, msgOK ;} если это так, выводим соответствующее
 mov edx, lenOK ;} сообщение
 int 0x80       ;}

 mov al, [n]    ;}
 mov bl, [m]    ;} заносим значения n и m в регистры
 sub al, '0'    ;} и делаем их цифрами вместо символов
 sub bl, '0'    ;}

 cmp al, 0      ;}
 je nIsZeroLabel    ;}
 cmp al, 1      ;} сообщения об особых случаях
 je nIsOneLabel ;}
 cmp bl, 0      ;}
 je mIsZeroLabel    ;}

 mov [powered], al          ;} заносим значение n в переменную
 mov [repetitionsNumber], bl    ;} заносим значение m в переменную
 xor ecx, ecx               ;} для указания количества итераций
 xor edx, edx ; и обнуляем регистры
 
conditionsCheck: ; внешний цикл
 mov edx, [powered]         ;} обновляем значение edx,
                        ;} т.к. нам нужно увеличивать  
 cmp byte [repetitionsNumber], 1    ;} его после каждой итерации

 jle stopPowering ; проверка на выполнение m - 1 повторений
 mov cl, al  ; заводим счётчик для цикла loop
 sub cl, 1 
 sub byte [repetitionsNumber], 1 ; уменьшаем внешний счётчик
 powering: ; внутренний цикл
  add [powered], edx ; выполняем сложение
  loop powering 
  jmp conditionsCheck   ;} после завершения loop выполняем 
                ;} прыжок на внешний цикл

 stopPowering: ; сложение окончено, подготовка деления
 xor ecx, ecx   ; очищаем ecx
 mov edx, 0 ;} заносим 0 в edx (старшая часть учетверённого слова),
        ;} т.к. нам нужно выполнить деление именно для него,
        ;} потому что частное от деления может не поместиться
        ;} в регистр al или ax
 mov eax, [powered] ;} заносим полученный результат
                ;} в младшую часть
 mov ebx, 10 ; заносим делитель в ebx

putResultInStack:   ; поочерёдно заносим цифры в стек
 div ebx    ; берём остаток от деления на 10
 push edx   ; кладём его в стек
 xor edx,edx     ; очищаем
 inc ecx    ; считаем длину числа
 test eax, eax ; проверяем, не дошли ли до нуля
 je output  ; если дошли, прыгаем на вывод
 jmp putResultInStack ; иначе повторяем деление

output: ; вывод сообщения об успехе и результата возведения
 mov [resultLength], ecx ; запоминаем длину числа

 mov eax, 4         ;}
 mov ebx, 1         ;}
 mov ecx, msgSuccess    ;} вывод сообщения об успешном 
 mov edx, lenSuccess    ;} завершении
 int 0x80           ;}
 
 xor eax, eax   ;}
 xor ecx, ecx   ;} очищаем регистры
 mov ecx, [resultLength]; заносим длину в ecx для loop

popResultIntoString: ; поэлементно записываем цифры в строку
 pop edx ; достаём элемент из стека
 add edx, byte 48 ; делаем из него обратно символ
 mov [strOutput + eax], edx ;} записываем в строку
                    ;} по нужному индексу
 inc eax ; используем счётчик для хождения по индексам
 loop popResultIntoString ; зацикливаем вывод

theEnd: ; вывод строки и выход из программы
 mov ecx, strOutput
 mov edx, eax
 mov ebx, 1
 mov eax, 4
 int 0x80
 
 jmp exit

nIsOneLabel: ; n - один и выход из программы
 mov eax, 4
 mov ebx, 1
 mov ecx, nIsOne
 mov edx, lennIsOne
 int 0x80

 jmp exit

nIsZeroLabel: ; n - ноль и выход из программы
 cmp bl, 0      ;} если n и m - нули, то 0 ^ 0 = 1
 je mIsZeroLabel    ;}
 
 mov eax, 4
 mov ebx, 1
 mov ecx, nIsZero
 mov edx, lennIsZero
 int 0x80
 
 jmp exit

mIsZeroLabel: ; m - ноль и выход из программы
 mov eax, 4
 mov ebx, 1
 mov ecx, mIsZero
 mov edx, lenmIsZero
 int 0x80

 jmp exit

error: ; введены неверные данные
 mov eax, 4
 mov ebx, 1
 mov ecx, msgError
 mov edx, lenError
 int 0x80
 
exit: ; выход из программы
 mov eax, 0x01
 mov ebx, 0
 int 0x80
