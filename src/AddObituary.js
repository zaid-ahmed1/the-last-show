import { useCallback, useEffect, useRef, useState } from "react";
import { v4 as uuidv4 } from 'uuid';

function AddObituary({ closePop }){
  
    const [isFilled, setIsFilled] = useState(true);
    const[name,setName] = useState("");
    const[bornWhen,setBornWhen] = useState("");
    const[deathWhen,setDeathWhen] = useState("");
    const[file,setFile] = useState(null);

    const close = () => {
        closePop();
    };

    const submitObit = async (e) => {

        document.getElementById("submit-btn").disabled = true;
        e.preventDefault();
        console.log(name,bornWhen,deathWhen,file);
        const data = new FormData();
        data.append("file",file);
        data.append("name",name);
        data.append("bornWhen",bornWhen);
        data.append("deathWhen",deathWhen);

        if(file === null || name === "" || bornWhen === "" || deathWhen === ""){
            setIsFilled(false);
        } 
        
        else{
            setIsFilled(true);
            document.getElementById("submit-btn").innerHTML = "Generating... Please wait";
            
            // CREATE OBITUARY FUNCTION:
            const promise = await fetch("https://5dvirwy4sayoeqep5nvk4dib3e0grgfo.lambda-url.ca-central-1.on.aws/", {
            method: "POST",
            headers:{
                "Authentification": "",
                "id":uuidv4()
            },
            body:data,
        });
            
            try{
                const response_content = await promise.json();
                const values = JSON.parse(response_content);
            }   
            catch{
                console.log("error");
            }
            
            close();
            window.location.reload()
            document.getElementById("submit-btn").disabled = false;
        }
    };

    const onFileChange = (e) =>{
        setFile(e.target.files[0]);
        document.getElementById("filename").innerHTML = "(" + e.target.files[0].name + ")";
    };

    const onBornChange = (e) => {
        setBornWhen(e.target.value);
    };

    const onDiedChange = (e) => {
        setDeathWhen(e.target.value);
    };
    

    return(
        <div id="pop-container">
            <button onClick={close} id="esc-btn">X</button>
            <h1>Create a New Obituary</h1>
            <img id="flower-img" src="http://clipart-library.com/images_k/black-and-white-flowers-transparent/black-and-white-flowers-transparent-11.png"></img>
            <form>
                <label>
                    Select an image for the deceased 
                    <input id="file-in" type="file" required accept="images/*" onChange={(e) => onFileChange(e)}/>
                    <span id="filename"></span>
                </label>
                <br/>
                <input id="name-in" type="text" placeholder="Name of the deceased" value={name} onChange={(e) => setName(e.target.value)}/>
                <div id="dates-in">
                    <p>Born:  <input onChange={onBornChange} type="date"/></p>
                    <p>Died:  <input onChange={onDiedChange} type="date"/></p>
                </div>
                {isFilled ? (<></>) : (<p id="error-msg">Please make sure that all fields are filled</p>)}
                <button id="submit-btn" type="button" onClick={submitObit}>Write Obituary</button>
            </form>
        </div>
    );
}


export default AddObituary;
