#! /usr/bin/env nix-shell
#! nix-shell deps.nix -i bash

# NOTE: what you see above is a [Nix shebang](https://nixos.org/nix/manual/#ssec-nix-shell-shebang).
# We used it instead of this shebang:
# #! /usr/bin/env bash
# because it allows us to specify and load the exact version of every required dependency.

OUTPUT_DIR='./cx'
BROKEN_EXT='broken'

for f in $(ls -1 $OUTPUT_DIR); do
	GOOD_PATH="$OUTPUT_DIR/$f"
	BROKEN_PATH="$GOOD_PATH.$BROKEN_EXT"
	mv "$GOOD_PATH" "$BROKEN_PATH"
	jq '.[-1] |= {status: [{success: true}]}' "$BROKEN_PATH" > "$GOOD_PATH"
	rm "$BROKEN_PATH"
done
