using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{
    public GameObject colve;
    // Start is called before the first frame update
    void Start()
    {
        this.gameObject.hideFlags = HideFlags.DontSave;
        //整个对象的inspector面板在运行时都不可编辑
        //this.gameObject.hideFlags = HideFlags.NotEditable;
        //对象上的某个属性在运行时不可编辑
        //this.GetComponent<Transform>().hideFlags = HideFlags.NotEditable;
        //运行时该对象不会出现在hierarchy面板上，但是scene视图和game视图上还能看到
        //this.hideFlags = HideFlags.HideInHierarchy;
        //在运行时该对象的inspector面板属性不可见
        // this.hideFlags = HideFlags.HideInInspector;
        //在运行时该对象在inspector的某个属性不可见
        //this.GetComponent<Transform>().hideFlags = HideFlags.HideInInspector;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.A))
        {
            GameObject go = Instantiate(colve);
            colve.hideFlags = HideFlags.DontSave;
        }
    }

    private void OnDisable()
    {
        DestroyImmediate(colve);
    }
}
