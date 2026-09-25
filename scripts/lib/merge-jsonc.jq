# Zachowaj literały tekstowe (w tym URL-e), usuń tylko komentarze i końcowe przecinki.
gsub("(?<keep>\"(?:\\\\.|[^\"\\\\])*\")|//[^\n]*|/\\*[\\s\\S]*?\\*/"; .keep // " ")
| gsub("(?<keep>\"(?:\\\\.|[^\"\\\\])*\")|,\\s*(?=[}\\]])"; .keep // "")
| if test("^\\s*$") then {} else fromjson end
| if type != "object" then error("Oczekiwano obiektu JSON") else . end
| . * $patch
