import React from 'react';
import {useState} from 'react';

function Obituary({obit, currentAudio, onPlay, onStop, created}){

    const [audio, setAudio] = useState(new Audio(obit.audio));

    const toggle = () => {
        const btn = document.getElementById("btn-" + obit.id);
        if (btn.innerHTML === "▶") {
            onPlay(audio);
            btn.innerHTML = "&#x23F8;";
            audio.addEventListener("ended", () => {
                btn.innerHTML = "&#9654;";
                onStop();
            });
            audio.addEventListener("pause", () => {
                btn.innerHTML = "&#9654;";
            });
        } else {
            btn.innerHTML = "&#9654;";
            onStop();
        }
    };

    const hideText = () => {
        const text = document.getElementById("text-" + obit.id);
        const btn = document.getElementById("btn-" + obit.id);
        if(text.style.display === "none"){
            text.style.display = "block";
            btn.style.display = "inline";

        } else{
            text.style.display = "none";
            btn.style.display = "none";
        }
    };

    return (
        <div className="obit-container" onLoad={created}>
            <img onClick={hideText} src={obit.img.replace("/upload/", "/upload/e_art:zorro/")}/>
            <h2 className="name">{obit.name}</h2>
            <h3 className="date">{obit.born} to {obit.died}</h3>
            <p id={"text-" + obit.id}>{obit.text}</p>
            <button id={"btn-" + obit.id} onClick={toggle} className="play-pause-btn">&#9654;</button>
        </div>
    );
}

export default Obituary;