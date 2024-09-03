#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.


# Create a temporary file to store unique team names
TEMP_FILE=$(mktemp)

# Extract unique teams from both 'winner' and 'opponent' columns and store in a temporary file
awk -F, 'NR > 1 {print $3; print $4}' games.csv | sort | uniq > "$TEMP_FILE"

# Insert unique teams into the teams table
while IFS= read -r team_name; do
  if [[ -n "$team_name" ]]; then
    # Check if the team already exists
    TEAM_EXISTS=$($PSQL "SELECT COUNT(*) FROM public.teams WHERE name = '$team_name';")
    
    if [[ $TEAM_EXISTS -eq 0 ]]; then
      # Insert the new team into the teams table
      $PSQL "INSERT INTO public.teams (name) VALUES ('$team_name');"
      echo "Inserted team: $team_name"
    else
      echo "Team already exists: $team_name"
    fi
  fi
done < "$TEMP_FILE"

# Clean up the temporary file
rm "$TEMP_FILE"

# Process the games.csv file and insert rows into the games table
while IFS=, read -r year round winner opponent winner_goals opponent_goals; do
  if [[ "$year" != "year" ]]; then  # Skip the header line
    # Get team IDs from the teams table
    winner_id=$($PSQL "SELECT team_id FROM public.teams WHERE name = '$winner';")
    opponent_id=$($PSQL "SELECT team_id FROM public.teams WHERE name = '$opponent';")

    # Insert data into games table
    $PSQL "INSERT INTO public.games (year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals);"
    echo "Inserted game: $year, $round, $winner ($winner_id) vs $opponent ($opponent_id), $winner_goals-$opponent_goals"
  fi
done < games.csv