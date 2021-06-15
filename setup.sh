#!/bin/bash

# Get the author's info
authorName=$(git config user.name)
authorEmail=$(git config user.email)

# Get current directory name (i.e. full project name)
projectName=${PWD##*/}

# Split name by dots
IFS='.'
read -ra projectParts <<<"$projectName"

# Get the org name (second part)
orgName=${projectParts[1]}
read orgNameProper <<< $(echo $orgName | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')

# Get project name (last parts)
defaultPackageName=${projectParts[${#projectParts[@]} - 1]}

IFS=' '
read -ra projectNameParts <<<"${projectParts[@]:3}"

defaultNamespace=$orgNameProper
defaultPackageName=$orgName\/
namespacePart=''

for p in "${projectNameParts[@]}"; do
  ## Split part by dashes
  IFS='-'
  read -ra nameParts <<<"$p"

  ## Build camel case namespace from parts
  namespacePart=''

  for np in "${nameParts[@]}"; do
    read camelPart <<< $(echo $np | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')
    namespacePart+=$camelPart
    defaultPackageName+=${np}-
  done

  defaultNamespace+=\/$namespacePart
done

defaultPackageName=${defaultPackageName:0:$((${#defaultPackageName} - 1))}

# Get user input
read -p "Enter your project namespace ($defaultNamespace): " namespace
namespace=${namespace:-$defaultNamespace}

# Get namespace without vendor
IFS='/'
read -ra namespaceParts <<<"$namespace"
partialNamespace=${namespaceParts[${#namespaceParts[@]} - 1]}
IFS=''

# Get slash escaped namespace
escapedNamespace="$(echo $namespace | sed 's/\//\\\\\\\\/g')\\\\\\\\"

read -p "Enter your project package name ($defaultPackageName): " packageName
packageName=${packageName:-$defaultPackageName}

echo "$namespace"
echo "$packageName"

# Update composer.json
sed -i '' "s|numenor/template|$packageName|" composer.json
sed -i '' "s|Numenor\\\\\\\\Template\\\\\\\\|$escapedNamespace|" composer.json
sed -i '' "s|George Burdell|$authorName|" composer.json
sed -i '' "s|user@example.com|$authorEmail|" composer.json

echo "Updated composer.json!"

# Update README.md
sed -i '' '2,4d' README.md
sed -i '' "s|numenor/template|$packageName|" README.md
sed -i '' "s|Template|$partialNamespace|" README.md

echo "Updated README.md!"

# Remove this shell script
echo "Removing setup script."
rm "$0"
