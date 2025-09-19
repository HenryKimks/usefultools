#!/bin/bash
# Script to change a specific background color of all PDF files to white.
# This version handles filenames with spaces and non-English characters.
# Usage: ./change_background.sh <input_directory> <output_directory> <background_color_hex>

# Check if arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <input_directory> <output_directory> <background_color_hex>"
    echo "Example: $0 input_pdfs output_pdfs #F0F8FF"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
BACKGROUND_COLOR="$3"

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory $INPUT_DIR does not exist."
    exit 1
fi

# Create output directory if it does not exist
mkdir -p "$OUTPUT_DIR"

# Start conversion
echo "Processing PDF files from $INPUT_DIR and saving to $OUTPUT_DIR ..."

for f in "$INPUT_DIR"/*.pdf; do
    [ -e "$f" ] || continue

    # 파일명에서 확장자를 제거하고, 안전한 이름으로 변환 (영어, 숫자, 하이픈만 남김)
    # 예를 들어 "10차시 딥러닝 이론 4.pdf" -> "10-deeplearning-theory-4"로 변환
    new_base=$(echo "$(basename "$f" .pdf)" | iconv -t ascii//TRANSLIT | sed 's/[^a-zA-Z0-9_-]//g' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    
    # 변환된 파일명을 출력 경로에 지정
    output="$OUTPUT_DIR/${new_base}.pdf"
    
    # 임시 디렉터리 생성 (페이지별 PNG 저장을 위해)
    temp_dir=$(mktemp -d)

    echo "Converting '$f'..."
    
    # Ghostscript를 사용하여 페이지 개수를 확인 (파일 경로를 따옴표로 감싸서 안전하게 처리)
    num_pages=$(gs -q -dNODISPLAY -c "($f) (r) file runpdfbegin pdfpagecount = quit")

    for (( i=0; i<num_pages; i++ )); do
        echo "  Processing page $((i+1)) of $num_pages..."
        # convert 명령어에 페이지 인덱스를 명시하고, 파일 경로를 따옴표로 감쌈
        convert -density 300 "$f[$i]" -fuzz 20% -transparent "$BACKGROUND_COLOR" -background white -flatten "${temp_dir}/${new_base}-page-${i}.png"
    done
    
    echo "Reassembling pages into a new PDF: $output"
    convert "${temp_dir}/${new_base}-page-*.png" "$output"

    rm -r "$temp_dir"
done

echo "All done"

