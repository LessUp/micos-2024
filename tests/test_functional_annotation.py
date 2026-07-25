# -*- coding: utf-8 -*-
"""测试功能注释模块（命令拼装层）。"""

from micos import functional_annotation


def test_run_functional_annotation_assembles_humann_command(tmp_path, monkeypatch):
    """run_functional_annotation 应合并 reads 并拼装 HUMAnN 命令."""
    commands = []

    def fake_run(cmd):
        commands.append(list(cmd))

    monkeypatch.setattr(functional_annotation, 'run_command_live', fake_run)

    input_dir = tmp_path / 'input'
    input_dir.mkdir()
    (input_dir / 'sample001_paired_1.fastq').write_text('r1')
    (input_dir / 'sample001_paired_2.fastq').write_text('r2')

    output_dir = tmp_path / 'output'
    functional_annotation.run_functional_annotation(
        input_dir=input_dir,
        output_dir=output_dir,
        threads=8,
    )

    assert len(commands) == 1
    humann_cmd = commands[0]
    assert humann_cmd[0] == 'humann'
    assert '--input' in humann_cmd
    assert str(output_dir) in humann_cmd
    assert humann_cmd[humann_cmd.index('--threads') + 1] == '8'
    assert humann_cmd[humann_cmd.index('--output-basename') + 1] == 'sample001'

    # 临时输入目录应被清理
    assert not (output_dir / 'temp_humann_input').exists()


def test_run_functional_annotation_skips_when_no_samples(tmp_path, monkeypatch):
    """无样本时应直接返回，不调用任何命令."""
    commands = []
    monkeypatch.setattr(
        functional_annotation,
        'run_command_live',
        lambda cmd: commands.append(list(cmd)),
    )

    input_dir = tmp_path / 'empty'
    input_dir.mkdir()
    output_dir = tmp_path / 'output'

    functional_annotation.run_functional_annotation(
        input_dir=input_dir,
        output_dir=output_dir,
        threads=4,
    )

    assert commands == []
