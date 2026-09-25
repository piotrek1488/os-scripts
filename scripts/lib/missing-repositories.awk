# Generuje tylko brakujące aktywne repozytoria. Ostatni plik to katalog repozytoriów.
# Źródła użytkownika pozostają nienaruszone; klucze trafiają do wyniku bez zmian.
BEGIN { RS=""; ORS="\n\n" }
function field(name,    rows,n,i,line,value,found) {
    n=split($0,rows,"\n")
    for(i=1;i<=n;i++) {
        line=rows[i]; sub(/\r$/, "", line)
        if(line ~ /^[ \t]*#/) continue
        if(line ~ /^[ \t]/) {
            if(found) { sub(/^[ \t]+/, "", line); value=value " " line }
        } else {
            if(found) break
            if(tolower(substr(line,1,length(name)+1)) == tolower(name) ":") {
                value=substr(line,length(name)+2); sub(/^[ \t]+/, "", value); found=1
            }
        }
    }
    sub(/[ \t]+$/, "", value)
    return value
}
function normalized(uri) {
    sub(/^https?:\/\//, "", uri); sub(/\/+$/, "", uri)
    sub(/^ppa\.launchpad\.net\//, "ppa.launchpadcontent.net/", uri)
    return uri
}
FILENAME != catalog {
    if(FILENAME ~ /\.sources$/) {
        if(tolower(field("Enabled")) == "no" || field("Types") !~ /(^|[ \t])deb([ \t]|$)/) next
        count=split(field("URIs"),uris,/[ \t]+/)
        for(i=1;i<=count;i++) if(uris[i] != "") existing[normalized(uris[i])]=1
    } else {
        count=split($0,lines,"\n")
        for(i=1;i<=count;i++) {
            line=lines[i]; sub(/^[ \t]+/, "", line)
            if(line !~ /^deb[ \t]+/) continue
            sub(/^deb[ \t]+/, "", line)
            sub(/^\[[^]]*\][ \t]+/, "", line)
            split(line,parts,/[ \t]+/)
            existing[normalized(parts[1])]=1
        }
    }
    next
}
tolower(field("Enabled")) != "no" && field("Types") ~ /(^|[ \t])deb([ \t]|$)/ {
    uri=field("URIs")
    # Każda definicja w katalogu musi mieć jeden adres, aby wybór był jednoznaczny.
    if(uri == "" || uri ~ /[ \t]/) {
        print "BŁĄD: definicja repozytorium musi mieć pojedynczy URI." > "/dev/stderr"
        exit 1
    }
    if(!(normalized(uri) in existing)) {
        print $0
        existing[normalized(uri)]=1
    }
}
