import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

document.addEventListener('DOMContentLoaded', () => {
    // --- Éléments du DOM ---
    const inputSequenceEl = document.getElementById('inputSequence');
    const inputVisualizerEl = document.getElementById('inputVisualizer');
    const playButton = document.getElementById('playButton');
    const stopButton = document.getElementById('stopButton');
    const downloadButton = document.getElementById('downloadButton');
    const downloadStatusEl = document.getElementById('downloadStatus');
    const errorMessageEl = document.getElementById('errorMessage');
    const visualizationAreaEl = document.getElementById('visualizationArea');
    const noteDurationEl = document.getElementById('noteDuration');
    const pauseDurationEl = document.getElementById('pauseDuration');
    const oscillatorTypeEl = document.getElementById('oscillatorType');
    const accentGainEl = document.getElementById('accentGain');
    const normalGainEl = document.getElementById('normalGain');
    const scaleTypeEl = document.getElementById('scaleType');
    const baseFrequencyNotesEl = document.getElementById('baseFrequencyNotes');
    const baseFrequencyDirectEl = document.getElementById('baseFrequencyDirect');
    const frequencyMultiplierDirectEl = document.getElementById('frequencyMultiplierDirect');
    const abjadInputEl = document.getElementById('abjadInput');
    const calculateAbjadButton = document.getElementById('calculateAbjadButton');
    const abjadResultEl = document.getElementById('abjadResult');
    const threeJsContainer = document.getElementById('threeJsContainer');
    const mainCanvas = document.getElementById('mainCanvas');

    // --- Variables d'état Audio ---
    let audioContext;
    let masterGainNode;
    let sequenceTimeoutIds = [];
    let isPlaying = false;
    let currentPlayingTokenId = null;

    // --- Variables d'état Three.js ---
    let scene, camera, renderer, particles, particleGeometry, particleMaterial;
    let controls;
    const MAX_PARTICLES = 25000;

    // --- Mappings ---
    const abjadMap = {
        'أ': 1, 'ا': 1, 'إ': 1, 'آ': 1, 'ب': 2, 'ج': 3, 'د': 4, 'ه': 5, 'و': 6, 'ز': 7, 'ح': 8, 'ط': 9,
        'ي': 10, 'ك': 20, 'ل': 30, 'م': 40, 'ن': 50, 'ص': 60, 'ع': 70,
        'ف': 80, 'ض': 90, 'ق': 100, 'ر': 200, 'س': 300, 'ت': 400,
        'ث': 500, 'خ': 600, 'ذ': 700, 'ظ': 800, 'غ': 900, 'ش': 1000,
        'ة': 400
    };
    const sequentialArabicMap = {};
    const arabicLetters = "ابتثجحخدذرزسشصضطظعغفقكلمنهوي";
    for (let i = 0; i < arabicLetters.length; i++) { sequentialArabicMap[arabicLetters[i]] = i + 1; }
    sequentialArabicMap['أ'] = 1; sequentialArabicMap['إ'] = 1; sequentialArabicMap['آ'] = 1;
    sequentialArabicMap['ة'] = sequentialArabicMap['ت'];

    // --- Fonctions Audio ---
    function initAudioContext() {
        if (!audioContext || audioContext.state === 'closed') {
            try {
                audioContext = new (window.AudioContext || window.webkitAudioContext)();
                masterGainNode = audioContext.createGain();
                masterGainNode.connect(audioContext.destination);
                 console.log("AudioContext initialized successfully.");
            } catch(e) {
                console.error("Error initializing AudioContext:", e);
                errorMessageEl.textContent = "Erreur: Impossible d'initialiser l'audio.";
            }
        }
        if (audioContext && audioContext.state === 'suspended') {
            audioContext.resume().catch(e => console.error("AudioContext resume failed:", e));
        }
    }

    function playSoundUnitLive(frequency, totalDuration, oscillatorType, targetGain) {
        if (!audioContext || !isPlaying || frequency <= 0 || frequency > 20000) {
            console.warn(`[playSoundUnitLive] Freq ${frequency.toFixed(2)}Hz invalide, silence.`);
            if (visualizationAreaEl.textContent.startsWith("Joue:")) {
                 visualizationAreaEl.textContent += ` (silence)`;
            }
            return new Promise(resolve => {
                 const timeoutId = setTimeout(resolve, totalDuration * 1000);
                 sequenceTimeoutIds.push(timeoutId);
            });
        }

        const osc = audioContext.createOscillator();
        const noteGain = audioContext.createGain();
        osc.type = oscillatorType;
        osc.frequency.setValueAtTime(frequency, audioContext.currentTime);
        osc.connect(noteGain);
        noteGain.connect(masterGainNode);

        const actxTime = audioContext.currentTime;
        let attackTime = 0.02; let releaseTime = 0.1;  
        if (totalDuration < attackTime + releaseTime) { attackTime = totalDuration * 0.2; releaseTime = totalDuration * 0.3; }
        const sustainStartTime = actxTime + attackTime;
        const releaseStartTimePoint = actxTime + totalDuration - releaseTime;

        noteGain.gain.cancelScheduledValues(actxTime);
        noteGain.gain.setValueAtTime(0, actxTime);
        noteGain.gain.linearRampToValueAtTime(targetGain, sustainStartTime);
        if (releaseStartTimePoint > sustainStartTime) {
            noteGain.gain.setValueAtTime(targetGain, releaseStartTimePoint);
        }
        noteGain.gain.linearRampToValueAtTime(0.0001, actxTime + totalDuration);
       
        osc.start(actxTime);
        osc.stop(actxTime + totalDuration);
        osc.onended = () => { try { osc.disconnect(); noteGain.disconnect(); } catch(e) {} };

        return new Promise(resolve => {
            const timeoutId = setTimeout(resolve, totalDuration * 1000);
            sequenceTimeoutIds.push(timeoutId);
        });
    }

    function playSoundUnitOffline(frequency, totalDuration, oscillatorType, targetGain, audioCtx, destNode, startTime) {
         if (!audioCtx || frequency <= 0 || frequency > 20000) return;
         const osc = audioCtx.createOscillator();
         const noteGain = audioCtx.createGain();
         osc.type = oscillatorType;
         osc.frequency.setValueAtTime(frequency, startTime);
         osc.connect(noteGain);
         noteGain.connect(destNode);
         let attackTime = 0.02; let releaseTime = 0.1;
         if (totalDuration < attackTime + releaseTime) { attackTime = totalDuration * 0.2; releaseTime = totalDuration * 0.3; }
         const sustainStartTime = startTime + attackTime;
         const releaseStartTimePoint = startTime + totalDuration - releaseTime;
         noteGain.gain.cancelScheduledValues(startTime);
         noteGain.gain.setValueAtTime(0, startTime);
         noteGain.gain.linearRampToValueAtTime(targetGain, sustainStartTime);
         if (releaseStartTimePoint > sustainStartTime) { noteGain.gain.setValueAtTime(targetGain, releaseStartTimePoint); }
         noteGain.gain.linearRampToValueAtTime(0.0001, startTime + totalDuration);
         osc.start(startTime);
         osc.stop(startTime + totalDuration);
     }

    // --- Fonctions Three.js ---
    function updateParticleSystem(count) {
        if (!scene || !renderer) return;

        const particleCount = Math.min(count, MAX_PARTICLES);
        console.log(`Updating particles to: ${particleCount}`);

        if (particles) {
            scene.remove(particles);
            if(particleGeometry) particleGeometry.dispose();
            // Le matériel peut souvent être réutilisé
        }
       
        if (particleCount === 0) {
             particles = null; // S'assurer que la référence est nulle
             renderer.render(scene, camera);
             return;
        }

        const positions = new Float32Array(particleCount * 3);
        const colors = new Float32Array(particleCount * 3);
        const range = 20;

        for (let i = 0; i < particleCount * 3; i += 3) {
            positions[i] = (Math.random() - 0.5) * range;
            positions[i + 1] = (Math.random() - 0.5) * range;
            positions[i + 2] = (Math.random() - 0.5) * range;

            const color = new THREE.Color();
            color.setHSL(Math.random() * 0.3 + 0.55, 0.8, 0.6);
            colors[i] = color.r; colors[i + 1] = color.g; colors[i + 2] = color.b;
        }

        particleGeometry = new THREE.BufferGeometry();
        particleGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        particleGeometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

        if (!particleMaterial) {
            particleMaterial = new THREE.PointsMaterial({
                size: 0.08, vertexColors: true, sizeAttenuation: true,
                transparent: true, opacity: 0.7, blending: THREE.AdditiveBlending
            });
        }

        particles = new THREE.Points(particleGeometry, particleMaterial);
        scene.add(particles);
    }

    function initThreeJS() {
        try {
            scene = new THREE.Scene();
            camera = new THREE.PerspectiveCamera(75, threeJsContainer.clientWidth / threeJsContainer.clientHeight, 0.1, 1000);
            renderer = new THREE.WebGLRenderer({ canvas: mainCanvas, antialias: true, alpha: true });
            renderer.setSize(threeJsContainer.clientWidth, threeJsContainer.clientHeight);
            renderer.setClearColor(0x000000, 1);

            camera.position.z = 15;

            controls = new OrbitControls(camera, renderer.domElement);
            controls.enableDamping = true; controls.dampingFactor = 0.05;
            controls.minDistance = 5; controls.maxDistance = 50;

            window.addEventListener('resize', onWindowResize, false);
            updateParticleSystem(0);
            animate();
            console.log("Three.js initialized successfully.");
        } catch(e) {
            console.error("Error initializing Three.js:", e);
            errorMessageEl.textContent = "Erreur: Impossible d'initialiser la visualisation 3D.";
        }
    }

    function onWindowResize() {
         if (!camera || !renderer || !threeJsContainer) return;
        const width = threeJsContainer.clientWidth;
        const height = threeJsContainer.clientHeight;
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
        renderer.setSize(width, height);
    }

    function animate() {
        requestAnimationFrame(animate);
        if (controls) controls.update();

        if (particles) {
            particles.rotation.y += 0.0005; // Rotation lente
            particles.rotation.x += 0.0002;
        }
       
        if (renderer && scene && camera) {
           renderer.render(scene, camera);
        }
    }

    // --- Fonctions Utilitaires et Logique ---
    function toggleModeControls() {
        const soundMode = document.querySelector('input[name="soundMode"]:checked').value;
        document.getElementById('notesModeControls').style.display = (soundMode === 'notes') ? 'block' : 'none';
        document.getElementById('frequencyModeControls').style.display = (soundMode === 'frequency') ? 'block' : 'none';
    }
    window.toggleModeControls = toggleModeControls;

    function parseInput(text) {
        const parsedTokens = [];
        const isOnlyNumericAndSeparators = /^[0-9\s,.-]+$/.test(text.trim());
        const arabicMethod = document.querySelector('input[name="arabicMappingMethod"]:checked').value;
        const currentArabicMap = (arabicMethod === 'abjad') ? abjadMap : sequentialArabicMap;
        if (text.trim() === "") return [];
        if (isOnlyNumericAndSeparators && text.match(/[0-9]/)) {
            const rawSegments = text.split(/([\s,]+)/);
            let currentNumberStr = "";
            rawSegments.forEach(segment => {
                if (segment.match(/^[0-9.-]+$/) && !isNaN(parseFloat(segment))) {
                    currentNumberStr += segment;
                } else {
                    if (currentNumberStr) {
                        const numVal = parseFloat(currentNumberStr);
                        if (!isNaN(numVal)) { parsedTokens.push({ value: Math.round(numVal), originalToken: currentNumberStr, isAccented: false }); }
                        currentNumberStr = "";
                    }
                }
            });
             if (currentNumberStr) {
                const numVal = parseFloat(currentNumberStr);
                if (!isNaN(numVal)) { parsedTokens.push({ value: Math.round(numVal), originalToken: currentNumberStr, isAccented: false }); }
            }
        } else {
            const normalizedText = text.normalize('NFC');
            for (let i = 0; i < normalizedText.length; i++) {
                const char = normalizedText[i];
                const charCodeLatin = char.charCodeAt(0);
                let value = null; let isAccented = false;
                if (char >= 'A' && char <= 'Z') { value = charCodeLatin - 'A'.charCodeAt(0) + 1; isAccented = true; }
                else if (char >= 'a' && char <= 'z') { value = charCodeLatin - 'a'.charCodeAt(0) + 1; isAccented = false; }
                else if (currentArabicMap[char] !== undefined) { value = currentArabicMap[char]; isAccented = false; }
                if (value !== null) { parsedTokens.push({ value: Math.round(value), originalToken: char, isAccented: isAccented }); }
            }
        }
        return parsedTokens.filter(token => typeof token.value === 'number' && !isNaN(token.value));
    }
    function calculateAbjadSum(text) {
         let sum = 0;
        const normalizedText = text.normalize('NFC');
        for (let i = 0; i < normalizedText.length; i++) {
            const char = normalizedText[i];
            if (abjadMap[char] !== undefined) {
                sum += abjadMap[char];
            }
        }
        return sum;
    }
    function displayInputAsSpans(parsedDataWithOriginals) {
        inputVisualizerEl.innerHTML = '';
        parsedDataWithOriginals.forEach((tokenData, index) => {
            if (typeof tokenData.value === 'number') {
                const span = document.createElement('span');
                span.id = `token-${index}`;
                span.textContent = tokenData.originalToken;
                inputVisualizerEl.appendChild(span);
                if (index < parsedDataWithOriginals.length - 1) { inputVisualizerEl.appendChild(document.createTextNode(' ')); }
            }
        });
        inputSequenceEl.classList.add('hidden');
        inputVisualizerEl.classList.remove('hidden');
    }
    function hideInputVisualizer() {
        inputVisualizerEl.classList.add('hidden');
        inputSequenceEl.classList.remove('hidden');
        if (currentPlayingTokenId) {
            const el = document.getElementById(currentPlayingTokenId);
            if (el) el.classList.remove('token-highlight');
            currentPlayingTokenId = null;
        }
    }
    const scales = {
        chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        major: [0, 2, 4, 5, 7, 9, 11],
        naturalMinor: [0, 2, 3, 5, 7, 8, 10],
        pentatonicMajor: [0, 2, 4, 7, 9]
    };
    const getNoteFrequency = (number, scaleName, baseNoteFreq) => {
        const MAX_EFFECTIVE_OCTAVE_SHIFT = 5; const ABSOLUTE_MAX_FREQ = 18000; const ABSOLUTE_MIN_FREQ = 30;    
        const scaleIntervals = scales[scaleName] || scales.chromatic;
        const numNotesInScale = scaleIntervals.length;
        if (number <= 0) { return ABSOLUTE_MIN_FREQ; }
        const noteIndexInScale = (number - 1) % numNotesInScale;
        let octaveCycleShift = Math.floor((number - 1) / numNotesInScale);
        let actualOctaveShiftForCalculation = octaveCycleShift;
        if (octaveCycleShift > MAX_EFFECTIVE_OCTAVE_SHIFT) { actualOctaveShiftForCalculation = MAX_EFFECTIVE_OCTAVE_SHIFT; }
        const semitonesFromBase = scaleIntervals[noteIndexInScale] + (actualOctaveShiftForCalculation * 12);
        let calculatedFrequency = baseNoteFreq * Math.pow(2, semitonesFromBase / 12);
        if (calculatedFrequency > ABSOLUTE_MAX_FREQ) { calculatedFrequency = ABSOLUTE_MAX_FREQ; }
        else if (calculatedFrequency < ABSOLUTE_MIN_FREQ && calculatedFrequency > 0) { calculatedFrequency = ABSOLUTE_MIN_FREQ; }
        else if (calculatedFrequency <= 0) { calculatedFrequency = ABSOLUTE_MIN_FREQ; }
        return calculatedFrequency;
    };
    async function playSequence(parsedData) {
        initAudioContext();
        if (!audioContext) { errorMessageEl.textContent = "AudioContext non initialisé."; return; }

        const soundMode = document.querySelector('input[name="soundMode"]:checked').value;
        const noteDurationSec = parseFloat(noteDurationEl.value);
        const pauseMs = parseInt(pauseDurationEl.value, 10);
        const oscillatorType = oscillatorTypeEl.value;
        const accentedGain = parseFloat(accentGainEl.value);
        const nonAccentedGain = parseFloat(normalGainEl.value);
        const baseNoteFreq = parseFloat(baseFrequencyNotesEl.value);
        const scaleName = scaleTypeEl.value;
        const baseDirectFreq = parseFloat(baseFrequencyDirectEl.value);
        const directFreqMultiplier = parseFloat(frequencyMultiplierDirectEl.value);

        for (let i = 0; i < parsedData.length; i++) {
            if (!isPlaying) { throw new Error("Playback aborted by user"); }
            const tokenData = parsedData[i];
            const number = tokenData.value;
            const targetGain = tokenData.isAccented ? accentedGain : nonAccentedGain;
           
            if (currentPlayingTokenId) {
                 const prevEl = document.getElementById(currentPlayingTokenId);
                 if (prevEl) prevEl.classList.remove('token-highlight');
            }
            currentPlayingTokenId = `token-${i}`;
            const currentEl = document.getElementById(currentPlayingTokenId);
            if (currentEl) currentEl.classList.add('token-highlight');

            let frequency = 0;
            let displayInfo = `Num: ${number}${tokenData.isAccented ? ' (Accent!)': ''}`;
            if (soundMode === 'notes') {
                frequency = getNoteFrequency(number, scaleName, baseNoteFreq);
                displayInfo += ` -> Note (Fréq: ${frequency.toFixed(2)} Hz)`;
            } else {
                frequency = baseDirectFreq + (number * directFreqMultiplier);
                if (frequency > 18000) frequency = 18000;
                if (frequency < 30 && frequency > 0) frequency = 30; else if (frequency <=0) frequency = 30;
                displayInfo += ` -> Fréq: ${frequency.toFixed(2)} Hz`;
            }
            visualizationAreaEl.textContent = "Joue: " + displayInfo;
           
            await playSoundUnitLive(frequency, noteDurationSec, oscillatorType, targetGain);

            await new Promise(resolve => {
                const timeoutId = setTimeout(resolve, pauseMs);
                sequenceTimeoutIds.push(timeoutId);
            });
            if (!isPlaying) throw new Error("Playback aborted by user");
        }
    }
    function clearTimeoutsAndState() {
        sequenceTimeoutIds.forEach(timeoutId => clearTimeout(timeoutId));
        sequenceTimeoutIds = [];
        // Arrêter tous les sons en cours (plus complexe maintenant, mais on coupe le gain)
        if (masterGainNode && audioContext && audioContext.state !== 'closed') {
             masterGainNode.gain.cancelScheduledValues(audioContext.currentTime);
             masterGainNode.gain.setValueAtTime(0, audioContext.currentTime);
             // On le remettra à 1 dans finishPlayback ou au prochain play
        }
    }
    function finishPlayback() {
        isPlaying = false;
        playButton.disabled = false;
        stopButton.disabled = true;
        hideInputVisualizer();
        if (masterGainNode && audioContext && masterGainNode.gain && audioContext.state !== 'closed') {
             masterGainNode.gain.setValueAtTime(1, audioContext.currentTime);
        }
        if (currentPlayingTokenId) {
            const el = document.getElementById(currentPlayingTokenId);
            if (el) el.classList.remove('token-highlight');
            currentPlayingTokenId = null;
        }
        visualizationAreaEl.textContent = "Prêt.";
    }
    function bufferToWav(buffer, numChannels = 1) {
        const sampleRate = buffer.sampleRate;
        const format = 1; const bitDepth = 16;
        const bytesPerSample = bitDepth / 8;
        const blockAlign = numChannels * bytesPerSample;
        const byteRate = sampleRate * blockAlign;
        const data = buffer.getChannelData(0);
        const dataLength = data.length * bytesPerSample;
        const bufferLength = 44 + dataLength;
        const wavBuffer = new ArrayBuffer(bufferLength);
        const view = new DataView(wavBuffer);
        function writeString(view, offset, string) { for (let i = 0; i < string.length; i++) { view.setUint8(offset + i, string.charCodeAt(i)); } }
        let offset = 0;
        writeString(view, offset, 'RIFF'); offset += 4;
        view.setUint32(offset, 36 + dataLength, true); offset += 4;
        writeString(view, offset, 'WAVE'); offset += 4;
        writeString(view, offset, 'fmt '); offset += 4;
        view.setUint32(offset, 16, true); offset += 4;
        view.setUint16(offset, format, true); offset += 2;
        view.setUint16(offset, numChannels, true); offset += 2;
        view.setUint32(offset, sampleRate, true); offset += 4;
        view.setUint32(offset, byteRate, true); offset += 4;
        view.setUint16(offset, blockAlign, true); offset += 2;
        view.setUint16(offset, bitDepth, true); offset += 2;
        writeString(view, offset, 'data'); offset += 4;
        view.setUint32(offset, dataLength, true); offset += 4;
        for (let i = 0; i < data.length; i++, offset += 2) {
            let s = Math.max(-1, Math.min(1, data[i]));
            s = s < 0 ? s * 0x8000 : s * 0x7FFF;
            view.setInt16(offset, s, true);
        }
        return new Blob([view], { type: 'audio/wav' });
    }
    function createDownloadLink(blob) {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        document.body.appendChild(a); a.style = 'display: none';
        a.href = url; a.download = 'nombre_en_son.wav';
        a.click();
        window.URL.revokeObjectURL(url); document.body.removeChild(a);
    }
    async function renderAndDownload() {
        downloadStatusEl.textContent = 'Préparation du rendu...';
        const parsedData = parseInput(inputSequenceEl.value);
        if (!parsedData || parsedData.length === 0) { errorMessageEl.textContent = "Séquence vide."; downloadStatusEl.textContent = ''; return; }

        const noteDurationSec = parseFloat(noteDurationEl.value);
        const pauseMs = parseInt(pauseDurationEl.value, 10);
        const pauseSec = pauseMs / 1000;
        const totalDuration = parsedData.length * (noteDurationSec) + (parsedData.length -1) * pauseSec;
        const sampleRate = 44100;
        if (totalDuration <= 0) { errorMessageEl.textContent = "Durée nulle."; downloadStatusEl.textContent = ''; return; }

        downloadStatusEl.textContent = 'Rendu audio en cours...';
        downloadButton.disabled = true;

        try {
            const offlineCtx = new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, Math.ceil(sampleRate * totalDuration), sampleRate);
            const offlineMasterGain = offlineCtx.createGain();
            offlineMasterGain.connect(offlineCtx.destination);
           
            const soundMode = document.querySelector('input[name="soundMode"]:checked').value;
            const oscillatorType = oscillatorTypeEl.value;
            const accentedGain = parseFloat(accentGainEl.value);
            const nonAccentedGain = parseFloat(normalGainEl.value);
            const baseNoteFreq = parseFloat(baseFrequencyNotesEl.value);
            const scaleName = scaleTypeEl.value;
            const baseDirectFreq = parseFloat(baseFrequencyDirectEl.value);
            const directFreqMultiplier = parseFloat(frequencyMultiplierDirectEl.value);
            let currentTime = 0;

            parsedData.forEach(tokenData => {
                const number = tokenData.value;
                const targetGain = tokenData.isAccented ? accentedGain : nonAccentedGain;
                let frequency = 0;

                if (soundMode === 'notes') { frequency = getNoteFrequency(number, scaleName, baseNoteFreq); }
                else {
                    frequency = baseDirectFreq + (number * directFreqMultiplier);
                    if (frequency > 18000) frequency = 18000;
                    if (frequency < 30 && frequency > 0) frequency = 30; else if (frequency <=0) frequency = 30;
                }
               
                playSoundUnitOffline(frequency, noteDurationSec, oscillatorType, targetGain, offlineCtx, offlineMasterGain, currentTime);
                currentTime += noteDurationSec + pauseSec;
            });

            const renderedBuffer = await offlineCtx.startRendering();
            downloadStatusEl.textContent = 'Conversion en WAV...';
            const wavBlob = bufferToWav(renderedBuffer);
            downloadStatusEl.textContent = 'Préparation du téléchargement...';
            createDownloadLink(wavBlob);
            downloadStatusEl.textContent = 'Téléchargement lancé !';
        } catch (error) {
            console.error("Erreur rendu offline :", error);
            errorMessageEl.textContent = "Erreur création audio.";
            downloadStatusEl.textContent = 'Échec.';
        } finally {
             downloadButton.disabled = false;
             setTimeout(() => { downloadStatusEl.textContent = ''; }, 5000);
        }
    }

    // --- Écouteurs d'événements ---
    playButton.addEventListener('click', async () => {
        initAudioContext();
        if (isPlaying) { clearTimeoutsAndState(); isPlaying = false; }
        errorMessageEl.textContent = '';
        const originalInputText = inputSequenceEl.value;
        const parsedSoundTokens = parseInput(originalInputText);

        if (!parsedSoundTokens || parsedSoundTokens.length === 0) {
            errorMessageEl.textContent = "Séquence invalide ou vide.";
            visualizationAreaEl.textContent = "Erreur.";
            finishPlayback();
            return;
        }
       
        displayInputAsSpans(parsedSoundTokens);
        isPlaying = true;
        playButton.disabled = true;
        stopButton.disabled = false;
        visualizationAreaEl.textContent = "Lecture...";

        try {
            await playSequence(parsedSoundTokens);
            if (isPlaying) {
                visualizationAreaEl.textContent += " - Fin.";
                 finishPlayback(); // Call finish when done naturally
            }
        } catch (error) {
            if (error.message === "Playback aborted by user") {
                 visualizationAreaEl.textContent = "Arrêtée.";
                 finishPlayback(); // Also call finish when stopped
            } else {
                errorMessageEl.textContent = "Erreur : " + error.message;
                visualizationAreaEl.textContent = "Erreur.";
                console.error("Playback error:", error);
                 finishPlayback(); // Call finish on error too
            }
        }
    });
    stopButton.addEventListener('click', () => {
        isPlaying = false;
        clearTimeoutsAndState();
        finishPlayback(); // Call finishPlayback here
    });
    calculateAbjadButton.addEventListener('click', () => {
         const text = abjadInputEl.value;
        if (!text) {
            abjadResultEl.textContent = "Veuillez entrer du texte.";
            updateParticleSystem(0); // Mettre à 0 si vide
            return;
        }
        const sum = calculateAbjadSum(text);
        abjadResultEl.textContent = `Valeur Abjad : ${sum}`;
        updateParticleSystem(sum); // Mettre à jour les particules avec la somme
    });
    downloadButton.addEventListener('click', renderAndDownload);

    // --- Initialisation ---
    initThreeJS();
    stopButton.disabled = true;
    console.log("Application initialisée.");
});
