mkdir -p output
for f in *.ttf; do
    [ -e "$f" ] || continue
    docker run \
        --rm \
        -v "$f":/input \
        -v $(pwd)/output:/output \
        --user $(id -u) \
        rfvgyhn/nerd-font-patcher \
            --complete \
            --mono \
            --adjust-line-height \
            --window \
            -ext "${f##*.}"
done
