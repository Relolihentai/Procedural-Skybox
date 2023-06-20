using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightMove : MonoBehaviour
{
    public float RotationSpeed = 10f;
    private float x = -90;
    private void Start()
    {
        transform.localRotation = Quaternion.Euler(x, 0, 0);
    }
    void Update()
    {
        
    }
    private void FixedUpdate()
    {
        x -= RotationSpeed * Time.deltaTime;
        x %= 360;
        transform.localRotation = Quaternion.Euler(x, 0, 0);
    }
}
