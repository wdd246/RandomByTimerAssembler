dane segment
	kopia db 160 dup(?)
	napis db 0ah,0dh,'Witamy w programie!',0ah,0dh,'$'	
	random db 0,24,5,13,22,15,16,17,0,0,21,16,15,21,7,22,6,14,1,1,1,9,22,21,0,23,23,1,15,17,19,20,2,23,7,3,0,5,19,9,24,16,4,3,8,21,19,8,6,10,24,24,21,19,22,22,5,8,20,23,4,12,22,22,6,18,2,9,6,0,18,7,18,0,20,11,19,6,22,22,6,7,6,4,18,20,22,23,8,7,18,4,4,19,16,3,11,21,5,6,8,17,9,23,24,11,17,9,15,12,17,21,0,16,8,21,2,11,4,24,22,8,22,19,13,12,23,15,12,0,13,20,5,15,23,4,2,2,3,0,22,21,9,7,16,6,14,22,23,6,14,19,9,10,21,12,20,8,8,8,3,9,10,19,5,3,7,23,16,23,14,24,16,5,19,9,19,14,2,18,13,7,3,17,12,13,19,3,13,12,7,20,13,16,22,23,13,3,1,10,9,0,3,15,19,1,7,17,12,18,20,3,10,19,7,11,22,17,21,9,12,0,5,14,2,10,18,8,13,7,10,17,0,2,16,4,14,22,12,13,13,4,2,7,14,24,8,1,10,9,4,11,13,18,24,23 ;256 losowych wartości od 0-24
	ekran db '................................................................................$' ; 80 znaków na linie
	
dane ends	
;______________________________________________
stoss         segment
                dw    	100h dup(0)
top          	Label word
stoss          ends
;______________________________________________
prog           segment
                assume  cs:prog, ds:dane, ss:stoss
;______________________________________________				
start:          mov     ax,dane
                mov     ds,ax
                mov     ax,stoss
                mov     ss,ax
                mov     sp,offset top
;______________________________________________		
				;Wyświetlenie etykiety
				mov 	ah,09h
				mov 	dx,offset napis
				int 	21h
				mov 	ch,0
				mov 	cl,23 ;23 linijki + 1 etykieta + 1 koniec = 25 linijek
wypisz:			mov		ah,09h
				mov		dx,offset ekran ;wypisanie kropek
				int 	21h
				loop    wypisz
				xor 	dx,dx
;______________________________________________			
				;Rozpoczęcie działania programu
				;Wybieranie lini i zegar
powtorz:		xor		ax,ax				
				int		1ah	;Zapisanie czasu. Czas zapisywany jest w rejestrze DX (mlodsze) oraz CX (starsze). 1) the last power-on, 2) the last system reset, or 3) the last system-
							;timer time read or set.AL = 0 if 24 hours has not passed; else 1			
				mov		dh,0
				mov		si,dx ;Wartość zegara zapisujemy do rejestru SI
				mov		bl,random[si] ;Za pomocą wartości zegara pobieramy pseudolosową liczbę z łańcucha				
				mov		al,160 ;Oznaczenie wielkości linii - 160B				
				mul		bl     ;BL*AX -> AX wyznaczenie numeru linii. Wynik w dx ax	
;______________________________________________	
				;Kopiowanie lini do bloku
				mov		cx,80 ;licznik kroków w movsw. 80 znaków na linie 
				push	ds 	  ;data segment na stos
				pop		es	  ;stos:data segemnt -> extra segment
				push	ds    ;data segment na stos
				mov		si,ax 	;Źródło adresu danych dla movs. si<-numer lini
				push	ax 	;zapisanie numeru linii na stosie
				mov		di,offset kopia
				mov		ax,0B800h ;Zapisanie segemntu pamięci do AX - kolorowe karty graficzne. Początek pamicei dla kart graficznych
				mov		ds,ax ;Kopiowanie wylosowanej linii do bloku kopia				
				rep		movsw ;Kopiowanie znaków do bloku aż rejestr CX osiągnie wartość 0. Rejestr SI jest źródłem adresu danych, DI - adresu wyniku, a CX licznikiem kroków
							  ;przepisuje dane wskazywane przez DS:SI pod adres ES:DI
;______________________________________________		
				;Przesłanianie znaku
				mov		cx,80 ;licznik kroków w stosw. 80 znaków na linie 
				mov		es,ax ;Początek pamicei dla kart graficznych
				pop		di ;pobranie numeru lini z stosu
				push	di ;odłozenie numeru lini na stos
				mov		al,35 ;Wykorzystanie kodu ASCII # - znak 
				mov		ah,11110000b ;biała linia, czarne znaki
				rep		stosw ;Zasłonięcie linii. Rejestr SI jest źródłem adresu danych, DI - adresu wyniku, a CX licznikiem kroków
							  ;przesyła dane z AX do miejsca w pamięci wskazywanego przez ES:DI
;______________________________________________		
				;Odczekanie 1s
				mov		cx,16 ;0010h - milisekundy
				xor		dx,dx
				xor		ax,ax
				mov		ah,86h ;Oczekiwanie BIOSU
				int		15h ;Trwające ok.1 sekunde
;______________________________________________		
				;"Odkrycie" lini
				mov		cx,80 ;licznik kroków w movsw. 80 znaków na linie 
				pop		di	;pobranie numeru lini
				pop		ds	;extra segment -> data segment
				mov		si,offset kopia ;Zapisanie wcześniej pobranej lini do SI
				rep		movsw ;Przekopiowanie linii na terminal.Kopiowanie znaków do bloku aż rejestr CX osiągnie wartość 0. Rejestr SI jest źródłem adresu danych, DI - adresu 
							  ;CX licznikiem kroków .Przepisuje dane wskazywane przez DS:SI pod adres ES:DI
;______________________________________________		
				;Reczne przewanie
				mov		ah,01h ;Oczekiwanie BIOSU na wciśniecie przycisku
				int		16h ;Wciśnięty przycisk. Z=0 jeżeli wcisniety
				loopz 	powtorz
;______________________________________________					
koniec:			mov     ah,4ch ;Funkcja kończąca pracę programu
				mov	    al,0
				int	    21h
				
prog ends
end start