using System;

namespace Railhunter.Math
{
    /// <summary>
    /// Battle math library — per ADR-0011 damage bounds + battle-core-loop GDD.
    /// C# mirror of src/math/battle_math_lib.gd (the actual game uses GDScript;
    /// this C# exists so the .NET assembly is well-formed and Godot's mono
    /// export can include the assembly metadata).
    /// </summary>
    public static class BattleMathLib
    {
        public const int MinDamage = 10;
        public const int MaxDamage = 480;
        public const int BossOneShotImmuneThreshold = 50;

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
    }
}
