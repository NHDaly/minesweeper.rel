# setup.sh database engine
# This setup file uses the RAI CLI to set up the minesweeper database

DATABASE="$1"
ENGINE="$2"

echo "database: $DATABASE"
echo "engine: $ENGINE"

set -x  # print commands before running
set -e  # exit on error

# Delete the DB if it already exists
rai delete-database "$DATABASE" -q
rai create-database "$DATABASE"
# Don't error if the engine already exists
rai create-engine "$ENGINE" --size="S" -q  || echo "Engine already exists"

# Dummy warmup
rai exec "$DATABASE" -e "$ENGINE" -c '2+2+2'

# Load the models from the position of this file
(
    cd $(dirname "$0");
    rai load-models "$DATABASE" -e "$ENGINE" ./model/mines.rel ./model/display.rel \
            ./model/init.rel ./model/coords.rel ./model/actions.rel
)

# Workaround for FD bug: Clear out the inserted tests and flags
rai exec "$DATABASE" -e "$ENGINE" -c 'def insert:reset = true'

# Warm up the display relation
echo "First run: warmup........."
rai exec "$DATABASE" -e "$ENGINE" -c 'display'

# Warm up some transactions
rai exec "$DATABASE" -e "$ENGINE" -c 'def insert:test = ^Coord[5, 5]'
rai exec "$DATABASE" -e "$ENGINE" -c 'display'
rai exec "$DATABASE" -e "$ENGINE" -c 'def insert:reset = true'
rai exec "$DATABASE" -e "$ENGINE" -c 'display'

