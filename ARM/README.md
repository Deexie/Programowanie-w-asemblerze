# Przepływ ,,zanieczyszczeń'' na ARMie

Naszym celem będzie napisanie funkcji symulujących fikcyjny przepływ pewnej wartości pseudofizycznej (o wartościach z dziedziny liczb rzeczywistych) przez prostokątną siatkę. Dla ułatwienia nazwijmy tę wartość zanieczyszczeniem. Program ma działać na procesorze ARM.

Dana jest prostokątna siatka w postaci tablicy dwuwymiarowej (oczywiście program może na swoje potrzeby trzymać to w innej postaci, ale mówimy o zewnętrznej, ,,logicznej'' reprezentacji). W każdej komórce przechowujemy bieżącą wartość zanieczyszczenia w tej okolicy.

Zakładamy, że przepływ zanieczyszczeń odbywa się od lewej do prawej. Symulacja odbywać się będzie krokowo. W każdym kroku na lewym brzegu tablicy pojawiają się nowe, wejściowe wartości. We wszystkich pozostałych miejscach zmiana wartości następuje przez równoczesne policzenie przyrostu na podstawie wartości w sąsiednich komórkach.

Dla komórek wewnętrznych za sąsiednie uznajemy 3 komórki po lewej stronie oraz 2 komórki powyżej i poniżej. Komórek z prawej strony nie bierzemy pod uwagę. Dla komórek na górnej i dolnej krawędzi bierzemy pod uwagę tylko trzech sąsiadów.

Policzenie przyrostu dla danej komórki polega na zsumowaniu (z pewnymi niewielkimi wagami) różnic zanieczyszczeń między tą komórką i jej sąsiadami. Po obliczeniu przyrostów dla wszystkich komórek są one do nich dodawane, na lewym ,,wejściu'' pojawiają się nowe wartości i rozpoczynamy kolejny krok. Podczas liczenia przyrostów liczby przez chwilę mogą nie być znormalizowane, ale należy je finalnie znormalizować.

Część napisana w języku wewnętrznym powinna eksportować procedury wołane z C:

```
void start (int szer, int wys, fixed *M, fixed waga)
```

Przygotowuje symulację, np. inicjuje pomocnicze struktury.

Typ ```fixed``` (tu i dalej) to albo po prostu float, albo integer, ale o interpretacji stałopozycyjnej.

```
void step (fixed T[])
```

\Przeprowadza pojedynczy krok symulacji dla podanego wejścia (rozmiar tablicy ```T``` jest zgodny z parametrem wys powyżej. Po jej wykonaniu matryca ```M``` (przekazana przez parametr ```start```) zawiera nowy stan. 

Testowy program główny napisany w C powinien zainicjować matrycę M (przez wczytanie jej zawartości z pliku) i rozpocząć symulację. Po każdym wywołaniu procedury step powinno się wyświetlać aktualną sytuację -- może być tekstowo, jako macierz liczb.
