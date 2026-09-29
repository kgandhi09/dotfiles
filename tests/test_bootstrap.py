"""Offline integration checks; all writes stay in temporary homes."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / "test-bin"
        self.bin.mkdir()
        self.log = self.home / "commands"
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=f"{self.bin}:/usr/bin:/bin", TEST_LOG=str(self.log))
        for key in ("WAYLAND_DISPLAY", "DISPLAY", "ZDOTDIR"):
            self.env.pop(key, None)

    def executable(self, path, body):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)

    def run_bootstrap(self, *args):
        return subprocess.run(["/bin/sh", str(REPO / "bootstrap-jk-os.sh"), *args],
                              env=self.env, capture_output=True, text=True)

    def fake_environment(self):
        prefix = self.home / ".local/share/dotfiles/env"
        (prefix / "conda-meta").mkdir(parents=True)
        (prefix / "conda-meta/history").touch()
        self.executable(prefix / "bin/bash", 'printf "bash %s\\n" "$*" >> "$TEST_LOG"')
        self.executable(prefix.parent / "micromamba", 'printf "mamba %s\\n" "$*" >> "$TEST_LOG"')
        return prefix

    def test_help_and_bad_option_do_not_install(self):
        self.assertEqual(self.run_bootstrap("--help").returncode, 0)
        self.assertNotEqual(self.run_bootstrap("--typo").returncode, 0)
        self.assertFalse((self.home / ".local").exists())

    def test_maintenance_requires_existing_environment(self):
        result = self.run_bootstrap("--links-only")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("full bootstrap first", result.stderr)
        self.assertFalse((self.home / ".local").exists())

    def test_maintenance_never_runs_package_manager_or_extras(self):
        self.fake_environment()
        for flag in ("--links-only", "--herdr-plugins", "--zsh-only"):
            result = self.run_bootstrap(flag)
            self.assertEqual(result.returncode, 0, result.stderr)
        log = self.log.read_text()
        self.assertNotIn("mamba", log)
        self.assertNotIn("jk-os-extras", log)
        self.assertIn("--no-deps --no-chsh --links-only", log)
        self.assertFalse((self.home / ".local/share/konsole").exists())

    def shell_repair_fixture(self):
        custom = self.home / ".oh-my-zsh/custom"
        for plugin in ("fzf-tab", "zsh-autosuggestions", "zsh-syntax-highlighting", "sshinfo"):
            (custom / "plugins" / plugin).mkdir(parents=True)
        theme = custom / "themes/powerlevel10k"
        theme.mkdir(parents=True)
        (theme / "keep.txt").write_text("preserve this incomplete checkout")
        return theme

    def run_shell_repair(self):
        return subprocess.run(["/bin/bash", str(REPO / "install.sh"), "--zsh-only", "--no-chsh"],
                              env=self.env, capture_output=True, text=True)

    def test_shell_repair_recovers_incomplete_theme_and_only_links_shell(self):
        theme = self.shell_repair_fixture()
        self.executable(self.bin / "git", 'for dest do :; done\nmkdir -p "$dest"\n'
                        'printf "# theme\\n" > "$dest/powerlevel10k.zsh-theme"')
        result = self.run_shell_repair()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((theme / "powerlevel10k.zsh-theme").exists())
        self.assertEqual(len(list(self.home.glob(".dotfiles-backup/*/powerlevel10k/keep.txt"))), 1)
        self.assertTrue((self.home / ".zshrc").is_symlink())
        self.assertTrue((self.home / ".p10k.zsh").is_symlink())
        self.assertFalse((self.home / ".config/nvim").exists())

    def test_shell_repair_download_failure_preserves_existing_theme(self):
        theme = self.shell_repair_fixture()
        self.executable(self.bin / "git", 'echo "network failed" >&2\nexit 1')
        result = self.run_shell_repair()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("network failed", result.stderr)
        self.assertTrue((theme / "keep.txt").exists())
        self.assertFalse((self.home / ".zshrc").exists())

    def test_full_bootstrap_handoff_and_profile(self):
        self.fake_environment()
        result = self.run_bootstrap("--no-fonts")
        self.assertEqual(result.returncode, 0, result.stderr)
        log = self.log.read_text()
        self.assertIn("mamba install", log)
        self.assertIn("--channel conda-forge", log)
        self.assertIn("jk-os-extras.sh", log)
        self.assertIn("--no-deps --no-chsh --no-fonts", log)
        profile = self.home / ".local/share/konsole/Dotfiles.profile"
        self.assertIn(str(self.home / ".local/bin/dotfiles-shell"), profile.read_text())
        self.assertIn("ColorScheme=Dotfiles", profile.read_text())
        scheme = self.home / ".local/share/konsole/Dotfiles.colorscheme"
        self.assertIn("[Background]\nColor=0,0,0", scheme.read_text())

    def test_console_login_hook_is_replaced_and_starts_zsh(self):
        prefix = self.fake_environment()
        self.executable(prefix / "bin/zsh", 'printf "zsh %s\\n" "$*" >> "$TEST_LOG"')
        profile = self.home / ".profile"
        profile.write_text("export KEEP=1\n")
        for _ in range(2):
            result = self.run_bootstrap("--no-deps")
            self.assertEqual(result.returncode, 0, result.stderr)
        content = profile.read_text()
        self.assertTrue(content.startswith("export KEEP=1\n"))
        self.assertEqual(content.count("# >>> dotfiles shell >>>"), 1)
        # A non-interactive login (scripts, the desktop session) keeps sh.
        result = subprocess.run(["/bin/sh", "-c", ". ~/.profile; echo still-sh"], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.stdout, "still-sh\n")
        self.assertNotIn("zsh", self.log.read_text())
        result = subprocess.run(["/bin/sh", "-i"], input=". ~/.profile\necho still-sh\n",
                                env=self.env, capture_output=True, text=True)
        self.assertNotIn("still-sh", result.stdout)
        self.assertIn("zsh -l", self.log.read_text())

    def test_dependency_failure_stops_before_installing_configs(self):
        prefix = self.fake_environment()
        self.executable(prefix.parent / "micromamba", "exit 23")
        result = self.run_bootstrap()
        self.assertEqual(result.returncode, 23)
        self.assertFalse(self.log.exists())
        self.assertFalse((self.home / ".local/share/konsole").exists())

    def test_no_deps_reuses_environment(self):
        self.fake_environment()
        result = self.run_bootstrap("--no-deps")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("mamba", self.log.read_text())
        self.assertNotIn("jk-os-extras", self.log.read_text())

    def test_shell_launcher_clears_host_python_settings(self):
        prefix = self.fake_environment()
        self.executable(prefix / "bin/zsh",
                        'printf "%s|%s|%s" "${PYTHONHOME-unset}" "${PYTHONPATH-unset}" "$SHELL"')
        self.env.update(PYTHONHOME="/wrong-python", PYTHONPATH="/wrong-modules")
        result = subprocess.run([str(REPO / "bin/dotfiles-shell")], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f"unset|unset|{prefix}/bin/zsh")

    def test_links_only_preserves_existing_config_and_is_repeatable(self):
        existing = self.home / ".zshrc"
        existing.write_text("original configuration\n")
        for _ in range(2):
            result = subprocess.run(["/bin/bash", str(REPO / "install.sh"), "--links-only"],
                                    env=self.env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(existing.is_symlink())
        backups = list((self.home / ".dotfiles-backup").glob("*/.zshrc"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "original configuration\n")
        self.assertTrue((self.home / ".local/bin/dotfiles-copy").is_symlink())

    def clipboard(self, wayland, x11):
        for tool in ("wl-copy", "xclip"):
            self.executable(self.bin / tool,
                            f'printf "{tool} %s\\n" "$*" >> "$TEST_LOG"\ncat >> "$TEST_LOG"')
        if wayland:
            self.env["WAYLAND_DISPLAY"] = "wayland-0"
        if x11:
            self.env["DISPLAY"] = ":0"
        return subprocess.run([str(REPO / "bin/dotfiles-copy")], env=self.env,
                              input="clipboard payload", capture_output=True, text=True)

    def test_wayland_preferred_when_xwayland_also_present(self):
        self.assertEqual(self.clipboard(True, True).returncode, 0)
        self.assertEqual(self.log.read_text(), "wl-copy \nclipboard payload")

    def test_x11_clipboard(self):
        self.assertEqual(self.clipboard(False, True).returncode, 0)
        self.assertEqual(self.log.read_text(), "xclip -selection clipboard\nclipboard payload")

    @unittest.skipUnless(shutil.which("zsh"), "zsh unavailable")
    def test_copy_functions_handle_shell_characters_in_filename(self):
        content = (REPO / "zsh/zshrc").read_text()
        functions = content[content.index("fcc() {"):content.index("# make aliases")]
        selected = self.home / "a ' file; $(touch SHOULD_NOT_EXIST)"
        selected.write_text("literal file contents")
        self.env["SELECTED"] = str(selected)
        self.executable(self.bin / "fzf", 'printf "%s\\0" "$SELECTED"')
        self.executable(self.bin / "dotfiles-copy", 'cat > "$TEST_LOG"')
        for function, expected in (("fcc", selected.read_text()), ("fpc", str(selected))):
            result = subprocess.run(["zsh", "-f", "-c", functions + "\n" + function],
                                    env=self.env, cwd=self.home, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.log.read_text(), expected)
        self.assertFalse((self.home / "SHOULD_NOT_EXIST").exists())


if __name__ == "__main__":
    unittest.main()
