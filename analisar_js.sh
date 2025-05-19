```bash
#!/bin/bash

# JS Analyzer Tool v1.0
# Autor: [Eliezer Liborio]
# Descrição: Ferramenta para análise de arquivos JavaScript/JSON

# Configurações
URL="seualvoaqui.json"  # Alvo a ser analisado
FILE="sha256.js"        # Nome do arquivo local
TEMP_FILE="temp_analysis.txt" # Arquivo temporário

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para limpeza
cleanup() {
    [ -f "$TEMP_FILE" ] && rm "$TEMP_FILE"
}

trap cleanup EXIT

echo -e "${YELLOW}[*] Baixando arquivo JS...${NC}"
if ! curl -s "$URL" -o "$FILE"; then
    echo -e "${RED}[!] Falha ao baixar o arquivo${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Buscando termos sensíveis...${NC}"
SENSITIVE_TERMS="secret|key|token|auth|bearer|password|apikey|credentials|private"
if grep -Pi "$SENSITIVE_TERMS" "$FILE" > "$TEMP_FILE"; then
    echo -e "${RED}"
    cat "$TEMP_FILE"
    echo -e "${NC}"
else
    echo -e "${GREEN}[-] Nenhum termo sensível encontrado.${NC}"
fi

echo ""
echo -e "${YELLOW}[*] Verificando sourcemap embutido...${NC}"
MAP=$(grep -oP '(?<=sourceMappingURL=data:application/json;base64,)[A-Za-z0-9+/=]+' "$FILE")

if [[ -n "$MAP" ]]; then
    echo -e "${GREEN}[+] Sourcemap embutido encontrado!${NC}"
    echo -e "${YELLOW}[*] Decodificando sourcemap para: $FILE.map.json${NC}"
    if ! echo "$MAP" | base64 -d > "$FILE.map.json"; then
        echo -e "${RED}[!] Falha ao decodificar sourcemap${NC}"
    else
        if command -v jq &>/dev/null; then
            echo -e "${YELLOW}[*] Exibindo resumo do sourcemap...${NC}"
            jq '.sources, .names, .file' "$FILE.map.json"
        else
            echo -e "${YELLOW}[!] Instale 'jq' para melhor visualização (sudo apt install jq)${NC}"
        fi
    fi
else
    echo -e "${GREEN}[-] Nenhum sourcemap embutido encontrado.${NC}"
fi

echo -e "${GREEN}[✓] Análise concluída.${NC}"
