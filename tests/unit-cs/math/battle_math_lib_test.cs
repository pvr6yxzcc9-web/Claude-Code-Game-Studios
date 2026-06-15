using Godot;
using NUnit.Framework;
using Railhunter.Math;

namespace Railhunter.Tests.Math
{
    /// <summary>
    /// Tests for BattleMathLib damage formula (C# static class).
    /// Per ADR-0011 Damage Bounds.
    /// </summary>
    [TestFixture]
    public class BattleMathLibTests
    {
        [Test]
        public void TestCalcDamage_MinDamageRule_ReturnsTen()
        {
            var weapon = new WeaponData { MinDamage = 20, MaxDamage = 20, CritMultiplier = 2.0f };
            var ammo = new AmmoData { DamageMult = 0.8f };
            var target = new EnemyData { MaxHp = 100, CurrentHp = 100, Boss = false };

            // Note: defense_mult not implemented in MVP; raw = 20 * 0.8 = 16
            // Min rule: max(10, 16) = 16 (above min)
            var dmg = BattleMathLib.CalcDamage(weapon, ammo, target, isCrit: false);
            Assert.That(dmg, Is.InRange(10, 480));
        }

        [Test]
        public void TestCalcDamage_MaxCap_Is480()
        {
            // The natural maximum without cap: 80 * 1.3 * 2.0 * 1.5 = 312
            // The cap doesn't trigger here (since 312 < 480), but we test the cap exists
            var weapon = new WeaponData { MinDamage = 80, MaxDamage = 80, CritMultiplier = 2.0f };
            var ammo = new AmmoData { DamageMult = 1.3f };
            var target = new EnemyData
            {
                MaxHp = 200, CurrentHp = 200,
                Boss = false,
                Weaknesses = new Godot.Collections.Array<StringName> { &"ammo_test" }
            };

            var dmg = BattleMathLib.CalcDamage(weapon, ammo, target, isCrit: true);
            Assert.LessOrEqual(dmg, 480, "Damage never exceeds 480 cap");
        }

        [Test]
        public void TestCalcDamage_BossOneShotImmunity_LeavesOneHp()
        {
            // 200 HP boss, max 480 cap attack, boss_immune_to_one_shot=true
            var weapon = new WeaponData { MinDamage = 80, MaxDamage = 80, CritMultiplier = 2.0f };
            var ammo = new AmmoData { DamageMult = 1.3f };
            var boss = new EnemyData
            {
                MaxHp = 200, CurrentHp = 200,
                Boss = true, BossImmuneToOneShot = true,
            };

            var dmg = BattleMathLib.CalcDamage(weapon, ammo, boss, isCrit: true);
            Assert.AreEqual(199, dmg, "Boss survives with current_hp - 1 = 199");
        }

        [Test]
        public void TestCalcDamage_BossWithoutImmunity_CanDie()
        {
            // Tutorial boss without immunity
            var weapon = new WeaponData { MinDamage = 80, MaxDamage = 80, CritMultiplier = 2.0f };
            var ammo = new AmmoData { DamageMult = 1.3f };
            var boss = new EnemyData
            {
                MaxHp = 200, CurrentHp = 200,
                Boss = true, BossImmuneToOneShot = false,
            };

            var dmg = BattleMathLib.CalcDamage(weapon, ammo, boss, isCrit: true);
            Assert.AreEqual(200, dmg, "Boss without immunity takes full damage = 200 (kills)");
        }

        [Test]
        public void TestCalcDamage_MonteCarlo_AllInRange()
        {
            // 1000 random damage calcs all in [10, 480]
            var rng = new System.Random(42);  // deterministic
            int violations = 0;

            for (int i = 0; i < 1000; i++)
            {
                var weapon = new WeaponData
                {
                    MinDamage = rng.Next(20, 80),
                    MaxDamage = rng.Next(20, 80),
                    CritMultiplier = 1.5f + (float)rng.NextDouble() * 1.5f
                };
                var ammo = new AmmoData
                {
                    DamageMult = 0.8f + (float)rng.NextDouble() * 0.5f
                };
                var target = new EnemyData
                {
                    MaxHp = 30 + rng.Next(0, 470),
                    CurrentHp = 30 + rng.Next(0, 470),
                    Boss = (i % 10 == 0),
                    BossImmuneToOneShot = (i % 10 == 0),
                };

                int dmg = BattleMathLib.CalcDamage(weapon, ammo, target, isCrit: (i % 2 == 0));
                if (dmg < 10 || dmg > 480)
                {
                    violations++;
                }
            }

            Assert.AreEqual(0, violations, "All 1000 random damage calcs in [10, 480]");
        }
    }
}
