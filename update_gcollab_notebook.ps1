param(
    [string]$NotebookPath = ".\GCollab\Lane_notebook.ipynb"
)

if (-not (Test-Path -Path $NotebookPath)) {
    throw "Notebook not found: $NotebookPath"
}

$nb = Get-Content -Path $NotebookPath -Raw | ConvertFrom-Json -Depth 100

$rtlCell = $nb.cells | Where-Object {
    $_.cell_type -eq "code" -and (($_.source -join "") -match 'rtl_dir = Path\.cwd\(\) / "rtl"')
} | Select-Object -First 1

if (-not $rtlCell) {
    throw "Could not locate the RTL preparation cell."
}

$rtlCell.source = @(
    "from pathlib import Path`n",
    "`n",
    "module_order = [`n",
    "    \"dla_pe.v\",`n",
    "    \"dla_pe_array.v\",`n",
    "    \"dla_controller.v\",`n",
    "    \"dla_a_buffer_bank.v\",`n",
    "    \"dla_b_buffer_bank.v\",`n",
    "    \"dla_engine_top.v\",`n",
    "]`n",
    "`n",
    "candidate_dirs = [`n",
    "    Path.cwd() / \"rtl\",`n",
    "    Path.cwd() / \"GCollab\" / \"rtl\",`n",
    "    Path.cwd(),`n",
    "]`n",
    "`n",
    "rtl_dir = None`n",
    "for candidate in candidate_dirs:`n",
    "    if all((candidate / name).exists() for name in module_order):`n",
    "        rtl_dir = candidate`n",
    "        break`n",
    "`n",
    "if rtl_dir is None:`n",
    "    raise FileNotFoundError(`n",
    "        \"Could not find all RTL .v files.\\n\"`n",
    "        \"Expected these files in either ./rtl, ./GCollab/rtl, or current folder:\\n\"`n",
    "        + \"\\n\".join(module_order)`n",
    "    )`n",
    "`n",
    "verilog_files = [str(rtl_dir / name) for name in module_order]`n",
    "print(f\"Using RTL directory: {rtl_dir}\")`n",
    "print(\"RTL files for synthesis:\")`n",
    "for path in verilog_files:`n",
    "    print(f\" - {path}\")"
)

$hasDownloadMd = $nb.cells | Where-Object {
    $_.cell_type -eq "markdown" -and (($_.source -join "") -match "### Download All Run Results")
} | Select-Object -First 1

if (-not $hasDownloadMd) {
    $downloadMd = [PSCustomObject]@{
        cell_type = "markdown"
        metadata = [PSCustomObject]@{ id = "downloadResultsMd" }
        source = @(
            "### Download All Run Results`n",
            "`n",
            "Setelah semua step selesai, cell di bawah akan membuat ZIP berisi seluruh direktori run LibreLane.`n",
            "Jika dijalankan di Google Colab, file ZIP akan otomatis di-download ke komputer Anda."
        )
    }

    $downloadCode = [PSCustomObject]@{
        cell_type = "code"
        execution_count = $null
        metadata = [PSCustomObject]@{ id = "downloadResultsCode" }
        outputs = @()
        source = @(
            "import shutil`n",
            "from pathlib import Path`n",
            "`n",
            "artifact_root = Path(\"colab_artifacts\")`n",
            "artifact_root.mkdir(exist_ok=True)`n",
            "`n",
            "step_objects = [`n",
            "    synthesis, floorplan, tdi, ioplace, pdn, gpl, dpl,`n",
            "    cts, grt, drt, fill, rcx, sta_post_pnr, gds, drc, spx, lvs`n",
            "]`n",
            "`n",
            "step_dirs = []`n",
            "for step_obj in step_objects:`n",
            "    step_dir = getattr(step_obj, \"step_dir\", None)`n",
            "    if step_dir:`n",
            "        step_dirs.append(Path(step_dir))`n",
            "`n",
            "if not step_dirs:`n",
            "    raise RuntimeError(\"Could not find LibreLane step directories to archive.\")`n",
            "`n",
            "run_root = step_dirs[0].parent`n",
            "archive_base = artifact_root / \"dla_engine_top_full_results\"`n",
            "archive_path = shutil.make_archive(str(archive_base), \"zip\", root_dir=run_root)`n",
            "`n",
            "final_state_path = artifact_root / \"final_state_out.json\"`n",
            "if hasattr(lvs.state_out, \"save_snapshot\"):`n",
            "    lvs.state_out.save_snapshot(str(final_state_path))`n",
            "    print(f\"Saved state snapshot: {final_state_path}\")`n",
            "`n",
            "print(f\"Run root: {run_root}\")`n",
            "print(f\"Created archive: {archive_path}\")`n",
            "`n",
            "try:`n",
            "    from google.colab import files`n",
            "    files.download(archive_path)`n",
            "except Exception:`n",
            "    print(\"Auto-download skipped. If you are not on Colab, download the ZIP manually from the file browser.\")"
        )
    }

    $nb.cells += $downloadMd
    $nb.cells += $downloadCode
}

$nb | ConvertTo-Json -Depth 100 | Set-Content -Path $NotebookPath -Encoding utf8
Write-Output "Notebook updated: $NotebookPath"

