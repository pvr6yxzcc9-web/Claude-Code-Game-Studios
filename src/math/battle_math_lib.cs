using System;

namespace Railhunter.Math
{
    /// <summary>
    /// Battle math library — per ADR-0011 damage bounds + battle-core-loop GDD.
    /// C# mirror of src/math/battle_math_lib.gd (the actual game uses GDScript;
    /// this C# exists so the .NET assembly is well-formed and Godot's mono
    /// export can include the assembly metadata).
    /// S7-009: Added 7 new formulas from party-system.md §4 (dodge, hit,
    /// crit, final damage, XP, revival cost, mech part damage).
    /// </summary>
    public static class BattleMathLib
    {
        public const int MinDamage = 10;
        public const int MaxDamage = 480;
        public const int BossOneShotImmuneThreshold = 50;

        // === S7-009 constants ===
        public const float MaxDodgeCap = 0.80f;
        public const float MinHitFloor = 0.05f;
        public const float MaxHitCeiling = 0.95f;
        public const int BaseXp = 100;
        public const int RevivalCostMin = 100;
        public const float RevivalCostRatio = 0.25f;

        public static int ClampDamage(int raw)
        {
            if (raw < MinDamage) return MinDamage;
            if (raw > MaxDamage) return MaxDamage;
            return raw;
        }

        public static int RollRange(int lo, int hi)
        {
            if (lo > hi) { int tmp = lo; lo = hi; hi = tmp; }
            if (lo == hi) return lo;
            int seed = Environment.TickCount;
            int span = hi - lo + 1;
            return lo + (((seed * 1103515245 + 12345) & 0x7FFFFFFF) % span);
        }

        public static int ComputeBaseDamage(int weaponMin, int weaponMax, float ammoMult, bool isCrit, float critMult)
        {
            if (weaponMax < weaponMin) { int tmp = weaponMin; weaponMin = weaponMax; weaponMax = tmp; }
            int raw = RollRange(weaponMin, weaponMax);
            float scaled = raw * ammoMult;
            if (isCrit) scaled *= critMult;
            return ClampDamage((int)System.Math.Round(scaled));
        }

        public static bool RollAccuracy(float accuracy)
        {
            if (accuracy < 0f) accuracy = 0f;
            if (accuracy > 1f) accuracy = 1f;
            int seed = Environment.TickCount;
            float v = (float)((seed * 1103515245 + 12345) & 0x7FFFFFFF) / (float)0x7FFFFFFF;
            return v <= accuracy;
        }

        public static int ApplyBossImmunity(int incomingDamage, int bossMaxHp, bool bossImmune)
        {
            if (!bossImmune) return incomingDamage;
            if (incomingDamage < bossMaxHp) return incomingDamage;
            int cap = (int)System.Math.Round(bossMaxHp * BossOneShotImmuneThreshold / 100.0);
            return System.Math.Min(incomingDamage, cap);
        }

        // === S7-009 New formulas (per party-system.md §4) ===

        // F1: Dodge chance — base 10% + level bonus (2% per level) + bonuses, capped at 80%
        public static float ComputeDodgeChance(
            int pilotLevel, float equipDodgeBonus, float passiveSkillBonus, float mechDodgeBonus)
        {
            float baseDodge = 0.10f;
            float levelBonus = pilotLevel * 0.02f;
            float raw = baseDodge + levelBonus + equipDodgeBonus + passiveSkillBonus + mechDodgeBonus;
            if (raw < 0f) raw = 0f;
            if (raw > MaxDodgeCap) raw = MaxDodgeCap;
            return raw;
        }

        // F2: Hit chance — base + accuracy - target_dodge - distance_penalty - cover_bonus
        public static float ComputeHitChance(
            float baseHit, float attackerAccuracy, float weaponAccuracy,
            float targetDodge, int distance, bool targetInCover)
        {
            float distancePenalty = distance * 0.05f;  // 5% per tile
            float coverBonus = targetInCover ? 0.05f : 0.0f;
            float raw = baseHit + attackerAccuracy + weaponAccuracy - targetDodge - distancePenalty - coverBonus;
            if (raw < MinHitFloor) raw = MinHitFloor;
            if (raw > MaxHitCeiling) raw = MaxHitCeiling;
            return raw;
        }

        // F3: Crit chance — base + bonuses, clamped 0..1
        public static float ComputeCritChance(
            float baseCrit, float pilotCritBonus, float weaponCritBonus, float ammoCritBonus)
        {
            float raw = baseCrit + pilotCritBonus + weaponCritBonus + ammoCritBonus;
            if (raw < 0f) raw = 0f;
            if (raw > 1f) raw = 1f;
            return raw;
        }

        // F4: Final damage — weapon roll × ammo × weakness × crit, minus armor (min 1)
        public static int ComputeFinalDamage(
            int weaponMinDmg, int weaponMaxDmg, float ammoMult,
            float weaknessMult, float critMult, bool isCrit, int targetArmor)
        {
            int baseDmg = RollRange(weaponMinDmg, weaponMaxDmg);
            float withAmmo = baseDmg * ammoMult;
            float withWeakness = withAmmo * weaknessMult;
            float withCrit = isCrit ? withWeakness * critMult : withWeakness;
            int final = (int)(withCrit - targetArmor);
            if (final < 1) final = 1;
            return final;
        }

        // F5: XP to next level — 100 × level^1.5
        public static int ComputeXPToNextLevel(int currentLevel)
        {
            if (currentLevel < 1) currentLevel = 1;
            return (int)(BaseXp * Math.Pow(currentLevel, 1.5));
        }

        // F6: Revival cost — max(floor(gold × 0.25), 100)
        public static int ComputeRevivalCost(int currentGold)
        {
            int cost = (int)Math.Floor(currentGold * RevivalCostRatio);
            if (cost < RevivalCostMin) cost = RevivalCostMin;
            return cost;
        }

        // F7: Mech part damage — max(0, floor(incoming × partArmorMult) - partArmor)
        public static int ComputeMechPartDamage(int incomingDmg, float partArmorMult, int partArmor)
        {
            int scaled = (int)(incomingDmg * partArmorMult) - partArmor;
            if (scaled < 0) scaled = 0;
            return scaled;
        }
    }
}