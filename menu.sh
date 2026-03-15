#!/bin/bash

# ==========================================
# 🤖 AIOps GitOps Architecture - Chaos Engine 🤖
# ==========================================

BRANCH="main"
clear

# --- STEP 1: SELECT TARGET ---
echo "================================================="
echo " TARGET SELECTION"
echo "================================================="
echo "Which microservice would you like to sabotage?"
echo "  1) 🌐 Frontend"
echo "  2) ⚙️  Backend"
echo "  3) 🗄️  MongoDB"
echo "  4) 🚪 Exit"
read -p "Select target [1-4]: " target_choice

case $target_choice in
    1) FILE_PATH="k8s/frontend-deployment.yml"; TARGET_NAME="Frontend" ;;
    2) FILE_PATH="k8s/backend-deployment.yml"; TARGET_NAME="Backend" ;;
    3) FILE_PATH="k8s/mongo-deployment.yml"; TARGET_NAME="MongoDB" ;;
    4) echo "Exiting safely."; exit 0 ;;
    *) echo "❌ Invalid option. Exiting."; exit 1 ;;
esac

# --- STEP 2: SELECT CHAOS ---
echo -e "\n================================================="
echo " CHAOS INJECTION FOR: $TARGET_NAME"
echo "================================================="
echo "Select a failure scenario to inject:"
echo "  1) 💥 Memory Starvation (Triggers OOMKilled - 1Mi Limit)"
echo "  2) 🛑 Bad Image Tag (Triggers ImagePullBackOff)"
echo "  3) 💽 Missing PVC (Deletes PVC file from Git) - MongoDB Only"
echo "  4) 🚪 Cancel"
read -p "Select scenario [1-4]: " chaos_choice

# Set default git action to add the modified file
GIT_ACTION="git add $FILE_PATH"

case $chaos_choice in
    1)
        echo -e "\n🔧 Sabotaging memory limits down to 1Mi in $FILE_PATH..."
        # Replaces any memory limit with a guaranteed-to-crash 1Mi
        sed -i 's/memory: .*/memory: "1Mi"/' $FILE_PATH
        COMMIT_MSG="Chaos: Injecting OOMKilled into $TARGET_NAME"
        ;;
    2)
        echo -e "\n🔧 Sabotaging the container image tag in $FILE_PATH..."
        # Appends a garbage string to the image name
        sed -i 's/image: .*/&_BROKEN-DEMO/' $FILE_PATH
        COMMIT_MSG="Chaos: Injecting ImagePullBackOff into $TARGET_NAME"
        ;;
    3)
        if [ "$TARGET_NAME" != "MongoDB" ]; then
            echo -e "\n❌ Error: Missing PVC scenario is only applicable to MongoDB. Exiting."
            exit 1
        fi
        echo -e "\n🔧 Sabotaging by completely deleting the PVC manifest from Git..."
        # Overrides git action to delete the specific PVC file
        GIT_ACTION="git rm k8s/mongodb-pvc.yml"
        COMMIT_MSG="Chaos: Deleted MongoDB PVC to force AI infrastructure generation"
        ;;
    4)
        echo -e "\nExiting safely. No chaos injected."
        exit 0
        ;;
    *)
        echo -e "\n❌ Invalid option. Exiting."
        exit 1
        ;;
esac

# --- STEP 3: EXECUTE ---
echo -e "\n📦 Pushing broken configuration to GitHub..."
$GIT_ACTION
git commit -m "$COMMIT_MSG"
git push origin $BRANCH

echo -e "\n✅ Chaos successfully pushed to $TARGET_NAME!"
echo "🐙 Argo CD is syncing the broken state..."
echo "👀 Keep an eye on your custom Discord bot for the AI remediation alert!"
