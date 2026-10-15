#!/bin/sh
# Runs headless test drivers one after the other and prints one line per test: PASS or FAIL (with the failing checks).
#   sh tools/run_tests.sh voice_data_test frontier_enter_test ...
#   sh tools/run_tests.sh nav_regions_test:frontier   (a driver with user arguments: name:arg1,arg2)
cd "$(dirname "$0")/.." || exit 1
mkdir -p tools/_shots
for spec in "$@"; do
	name="${spec%%:*}"
	args=""
	case "$spec" in
		*:*) args="-- $(echo "${spec#*:}" | tr ',' ' ')" ;;
	esac
	log="tools/_shots/run_$name.log"
	godot --path . --headless --script "tools/$name.gd" $args > "$log" 2>&1
	code=$?
	fails=$(grep -E "^FAIL|SCRIPT ERROR|Parse Error" "$log" | head -5)
	passes=$(grep -c "^PASS" "$log")
	if [ "$code" -eq 0 ] && [ -z "$fails" ]; then
		echo "PASS $name ($passes checks)"
	else
		echo "FAIL $name (exit $code, $passes passed)"
		echo "$fails"
	fi
done
echo "all done"
